package com.gangroll.gang_roll

import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Quick Shoot pinned-shortcut bridge + launch forwarding.
 *
 * Dart -> native:  isPinShortcutSupported, pinShortcut, removeShortcut,
 *                  getInitialShortcutMoment.
 * native -> Dart:  onShortcutLaunch (warm-start taps of the pinned icon).
 *
 * pinShortcut returns a rich map { success, reason, androidVersion } so the UI
 * can tell the user exactly what happened (esp. on ColorOS/MIUI launchers that
 * silently reject pinning). Every branch logs under tag "GangRollShortcut".
 */
class MainActivity : FlutterActivity() {
    private val channelName = "gangroll/shortcut"
    private val tag = "GangRollShortcut"
    private var channel: MethodChannel? = null
    private var pendingMomentId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Cold start: the launching intent may carry a moment (via data URI or
        // an explicit extra).
        pendingMomentId = momentFromIntent(intent)
        Log.i(tag, "configureFlutterEngine, initial momentId=$pendingMomentId")

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPinShortcutSupported" -> {
                    val supported = isPinShortcutSupported()
                    android.util.Log.d("GANGROLL_PIN",
                        "isRequestPinShortcutSupported = $supported")
                    result.success(supported)
                }
                "pinShortcut" -> {
                    val momentId = call.argument<String>("momentId") ?: ""
                    val momentName = call.argument<String>("momentName") ?: "Quick Shoot"
                    android.util.Log.d("GANGROLL_PIN",
                        "pinShortcut() called -> ShortcutManager.requestPinShortcut " +
                            "(NOT AppWidget). momentId=$momentId")
                    try {
                        result.success(pinShortcut(momentId, momentName))
                    } catch (e: Exception) {
                        Log.e(tag, "pinShortcut threw", e)
                        result.error("PIN_FAILED", e.message, null)
                    }
                }
                // Decision path: OEM silent launcher → legacy broadcast,
                // else → requestPinShortcut. (Investigation for Avenue 1.)
                "enableShortcut" -> {
                    val momentId = call.argument<String>("momentId") ?: ""
                    val momentName = call.argument<String>("momentName") ?: "Quick Shoot"
                    result.success(enableShortcut(momentId, momentName))
                }
                // Force the legacy INSTALL_SHORTCUT broadcast (Avenue 1 test).
                "pinShortcutLegacy" -> {
                    val momentId = call.argument<String>("momentId") ?: ""
                    val momentName = call.argument<String>("momentName") ?: "Quick Shoot"
                    result.success(createLegacyShortcut(momentId, momentName))
                }
                "removeShortcut" -> {
                    removeShortcut()
                    result.success(true)
                }
                "getInitialShortcutMoment" -> {
                    result.success(pendingMomentId)
                    pendingMomentId = null
                }
                else -> result.notImplemented()
            }
        }
    }

    // Warm start: app already running, user taps the pinned icon.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val momentId = momentFromIntent(intent)
        Log.i(tag, "onNewIntent, momentId=$momentId")
        if (momentId != null) channel?.invokeMethod("onShortcutLaunch", momentId)
    }

    private fun momentFromIntent(intent: Intent?): String? {
        if (intent == null) return null
        intent.data?.getQueryParameter("momentId")?.let { if (it.isNotEmpty()) return it }
        return intent.getStringExtra("momentId")
    }

    private fun isPinShortcutSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            Log.w(tag, "Android < 8.0 (sdk=${Build.VERSION.SDK_INT}) — pin unsupported")
            return false
        }
        val sm = getSystemService(ShortcutManager::class.java)
        val supported = sm?.isRequestPinShortcutSupported ?: false
        Log.i(tag, "isPinShortcutSupported=$supported")
        return supported
    }

    private fun pinShortcut(momentId: String, momentName: String): Map<String, Any?> {
        Log.i(tag, "pinShortcut momentId=$momentId name=$momentName")

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return mapOf(
                "success" to false,
                "reason" to "Android below 8.0 — pinning not supported.",
                "androidVersion" to Build.VERSION.SDK_INT,
            )
        }

        val sm = getSystemService(ShortcutManager::class.java)
            ?: return mapOf("success" to false, "reason" to "ShortcutManager unavailable.")

        if (!sm.isRequestPinShortcutSupported) {
            Log.w(tag, "launcher does NOT support pin")
            return mapOf(
                "success" to false,
                "reason" to "Your launcher doesn't support adding shortcuts.",
            )
        }

        // Explicit component + a momentId extra (no custom scheme) so every
        // launcher, including ColorOS/MIUI, accepts it. MainActivity reads the
        // extra on launch and forwards it to Flutter.
        //
        // IMPORTANT: do NOT add a "route" extra — FlutterActivity reserves the
        // "route" extra as its *initial route*, so it would make Flutter try to
        // navigate to that string on cold start (→ go_router "no route" error).
        // We open the camera ourselves via the method channel instead.
        val shortcutIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            putExtra("momentId", momentId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val icon: Icon = try {
            Icon.createWithResource(this, R.mipmap.ic_launcher)
        } catch (e: Exception) {
            Log.e(tag, "icon load failed", e)
            return mapOf("success" to false, "reason" to "Icon load failed: ${e.message}")
        }

        // Visible label is the literal lowercase "camera" (per product). The
        // moment binding lives in the intent's momentId extra, unchanged.
        val id = "quickshoot_$momentId"
        val shortcut = ShortcutInfo.Builder(this, id)
            .setShortLabel("camera")
            .setLongLabel("camera")
            .setIcon(icon)
            .setIntent(shortcutIntent)
            .build()

        // If we already pinned this shortcut before (and our OFF toggle later
        // disabled it), Android REJECTS a fresh requestPinShortcut for the same
        // id ("already exists but disabled"). So re-enable + update the existing
        // one instead — the icon is already on the home screen.
        val existing = sm.pinnedShortcuts.firstOrNull { it.id == id }
        if (existing != null) {
            sm.enableShortcuts(listOf(id))
            sm.updateShortcuts(listOf(shortcut))
            Log.i(tag, "re-enabled existing pinned shortcut $id")
            return mapOf(
                "success" to true,
                "alreadyPinned" to true,
                "reason" to "Quick Shoot is already on your home screen — re-enabled.",
            )
        }

        // Result callback so the launcher can confirm placement.
        val callbackIntent = sm.createShortcutResultIntent(shortcut)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_IMMUTABLE else 0
        val successCallback = PendingIntent.getBroadcast(this, 0, callbackIntent, flags)

        val requested = sm.requestPinShortcut(shortcut, successCallback.intentSender)
        Log.i(tag, "requestPinShortcut returned $requested")

        return mapOf(
            "success" to requested,
            "alreadyPinned" to false,
            "reason" to if (requested) {
                "System dialog should appear now."
            } else {
                "Launcher rejected the request silently."
            },
        )
    }

    // Whether ANY installed app registers a receiver for the legacy
    // INSTALL_SHORTCUT broadcast. On modern devices (verified: Realme/ColorOS,
    // Android 15) this is EMPTY — Google removed it from AOSP in Android 8 — so
    // the broadcast is a no-op and we must not route to it.
    private fun legacyReceiverExists(): Boolean {
        return try {
            packageManager.queryBroadcastReceivers(
                Intent("com.android.launcher.action.INSTALL_SHORTCUT"), 0,
            ).isNotEmpty()
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Avenue 1 — deprecated OEM broadcast. Fire-and-forget: there is NO success
     * callback, so the only way to know it worked is to look at the home screen.
     * On modern AOSP-based launchers this is ignored; some OEM launchers still
     * honor it (silently) when their shortcut permission is granted.
     */
    private fun createLegacyShortcut(momentId: String, momentName: String): Boolean {
        return try {
            val launchIntent = Intent(this, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra("momentId", momentId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val install = Intent("com.android.launcher.action.INSTALL_SHORTCUT").apply {
                putExtra(Intent.EXTRA_SHORTCUT_INTENT, launchIntent)
                putExtra(Intent.EXTRA_SHORTCUT_NAME, "camera")
                putExtra(
                    Intent.EXTRA_SHORTCUT_ICON_RESOURCE,
                    Intent.ShortcutIconResource.fromContext(
                        this@MainActivity, R.mipmap.ic_launcher),
                )
                putExtra("duplicate", false) // best-effort de-dupe
            }
            sendBroadcast(install)
            android.util.Log.d("GANGROLL_PIN",
                "legacy INSTALL_SHORTCUT broadcast SENT for '$momentName' " +
                    "(no callback — verify on home screen)")
            true
        } catch (e: Exception) {
            android.util.Log.e("GANGROLL_PIN", "legacy shortcut failed", e)
            false
        }
    }

    /**
     * Pick the lowest-friction path for this device and report which one ran.
     *
     * Decision (post-investigation): PREFER requestPinShortcut everywhere — it's
     * the universal, one-"Add"-tap, no-drag path. Only fall back to the legacy
     * broadcast if a receiver for it actually exists (essentially never on
     * modern devices; verified absent on Realme/ColorOS Android 15).
     */
    private fun enableShortcut(momentId: String, momentName: String): Map<String, Any?> {
        val sm = getSystemService(ShortcutManager::class.java)
        val pinSupported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            sm?.isRequestPinShortcutSupported == true
        val legacy = legacyReceiverExists()
        android.util.Log.d("GANGROLL_PIN",
            "enableShortcut: manufacturer=${Build.MANUFACTURER} " +
                "sdk=${Build.VERSION.SDK_INT} pinSupported=$pinSupported " +
                "legacyReceiverExists=$legacy")

        if (pinSupported) {
            val res = pinShortcut(momentId, momentName).toMutableMap()
            res["path"] = "pin"
            return res
        }
        if (legacy) {
            val sent = createLegacyShortcut(momentId, momentName)
            return mapOf(
                "success" to sent,
                "path" to "legacy",
                "needsPermissionHint" to true,
            )
        }
        return mapOf(
            "success" to false,
            "path" to "none",
            "reason" to "This launcher can't add home-screen shortcuts.",
        )
    }

    private fun removeShortcut() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) return
        val sm = getSystemService(ShortcutManager::class.java) ?: return
        val pinnedIds = sm.pinnedShortcuts
            .filter { it.id.startsWith("quickshoot_") }
            .map { it.id }
        if (pinnedIds.isNotEmpty()) sm.disableShortcuts(pinnedIds)
        sm.removeAllDynamicShortcuts()
        Log.i(tag, "removeShortcut: disabled ${pinnedIds.size} pinned, cleared dynamic")
    }
}
