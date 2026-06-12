// Screen B — Quick Shoot camera, styled to feel ~90% like the stock phone
// camera: edge-to-edge viewfinder, translucent glass controls in standard
// positions, zoom row, mode strip, tap-to-focus. The ONE non-native element is
// the centre "moment" pill (where shots land).
//
// Each capture is saved full-quality to the device gallery + app storage and
// queued as `pending` (NO upload here — that happens when the user opens the
// app and taps Resume). Launched at /camera?moment=<code>.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme.dart';
import '../../active_moment/data/active_moment_store.dart';
import '../../moments/data/mock_moments.dart';
import '../../moments/domain/moment.dart';
import '../data/models/pending_photo.dart';
import '../data/providers/photo_queue_provider.dart';
import '../data/services/local_storage_service.dart';

const _uuid = Uuid();
const _storage = LocalStorageService();
const _zoomStops = [0.5, 1.0, 2.0, 3.0];

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key, this.momentCode, this.shortcut = false});

  /// Pre-bound destination from the route. Falls back to the Quick Shoot
  /// binding, then the Active Moment.
  final String? momentCode;

  /// True when this camera was launched from the home-screen Quick Shoot
  /// shortcut. A shortcut launch is a *standalone* camera — it is NOT part of
  /// the app's navigation. Closing it (X / system back / thumbnail) exits to the
  /// launcher instead of diving into the app. Shots still flow to the moment's
  /// pending queue and surface next time the user opens the app normally.
  final bool shortcut;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  // Drives the top-right moment selector's wobble when capture is blocked.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  bool _permissionDenied = false;
  bool _initFailed = false;
  bool _capturing = false;
  bool _flashOverlay = false;

  FlashMode _flash = FlashMode.off;
  int _shotCount = 0;
  String? _lastThumbPath;

  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoom = 1;

  // Focus reticle position (in preview-local coords) + visibility.
  Offset? _focusPoint;
  Timer? _focusTimer;

  // Resolved capture destination (mutable — the moment pill can switch it).
  String? _momentCode;
  String _momentName = 'Pick a moment';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Native camera = light status-bar icons on a dark scene.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveDestination());
    _setup();
  }

  @override
  void dispose() {
    _shake.dispose();
    _focusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    // Restore the app's normal (dark icons on cream) system bars.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  /// Close the camera.
  ///
  ///   • Shortcut launch → exit the app entirely (back to the launcher). The
  ///     camera is standalone here; it must never reveal or navigate into the
  ///     app. Captured shots are already queued and appear when the app is
  ///     opened normally.
  ///   • In-app launch → land on the selected moment (showing the new shots);
  ///     if no moment was ever selected, just pop.
  void _close() {
    if (widget.shortcut) {
      SystemNavigator.pop();
      return;
    }
    final code = _momentCode;
    if (code != null) {
      context.pushReplacement('/moment/$code');
    } else {
      context.pop();
    }
  }

  /// Shutter pressed with no moment selected — wobble the selector + hint.
  void _wobbleSelector() {
    _shake.forward(from: 0);
    unawaited(HapticFeedback.mediumImpact());
    Fluttertoast.showToast(
      msg: 'Pick a moment first',
      gravity: ToastGravity.CENTER,
      backgroundColor: AppTheme.ink,
      textColor: AppTheme.cream,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initController(_cameras[_cameraIndex]);
    }
  }

  void _resolveDestination() {
    // Priority: shortcut-bound moment (route param) → last-selected (the
    // persisted Active Moment) → none. A moment that no longer exists (deleted
    // / left) resolves to none so we prompt instead of pointing at a ghost.
    final candidate =
        widget.momentCode ?? ref.read(activeMomentProvider)?.code;
    final m =
        candidate == null ? null : ref.read(momentByCodeProvider(candidate));
    setState(() {
      _momentCode = m?.code;
      _momentName = m?.title ?? 'Pick a moment';
    });
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _initFailed = true);
        return;
      }
      _cameras = cameras;
      _cameraIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_cameraIndex < 0) _cameraIndex = 0;
      await _initController(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      setState(() {
        if (e.code.toLowerCase().contains('denied')) {
          _permissionDenied = true;
        } else {
          _initFailed = true;
        }
      });
    }
  }

  Future<void> _initController(CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setFlashMode(_flash);
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = await controller.getMaxZoomLevel();
      _zoom = _zoom.clamp(_minZoom, _maxZoom);
      await controller.setZoomLevel(_zoom);
    } on CameraException catch (e) {
      setState(() {
        if (e.code.toLowerCase().contains('denied')) {
          _permissionDenied = true;
        } else {
          _initFailed = true;
        }
      });
      return;
    }
    if (mounted) setState(() {});
  }

  Future<void> _capture() async {
    final controller = _controller;
    final code = _momentCode;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    if (code == null) {
      // No destination → don't capture; nudge the selector to draw attention.
      _wobbleSelector();
      return;
    }

    setState(() {
      _capturing = true;
      _flashOverlay = true;
    });
    unawaited(HapticFeedback.lightImpact());
    Timer(const Duration(milliseconds: 80), () {
      if (mounted) setState(() => _flashOverlay = false);
    });

    try {
      final shot = await controller.takePicture();
      final capturedAtMs = DateTime.now().millisecondsSinceEpoch;
      final saved = await _storage.persist(
        sourcePath: shot.path,
        momentId: code,
        capturedAtMs: capturedAtMs,
      );
      await ref.read(photoQueueRepositoryProvider).insert(
            PendingPhoto(
              id: _uuid.v4(),
              localPath: saved.localPath,
              momentId: code,
              momentName: _momentName,
              status: PendingStatus.pending,
              capturedAt: DateTime.fromMillisecondsSinceEpoch(capturedAtMs),
            ),
          );
      if (mounted) {
        setState(() {
          _shotCount++;
          _lastThumbPath = saved.localPath;
        });
      }
    } on CameraException {
      // A single failed shot shouldn't kill the session.
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _cycleFlash() {
    setState(() {
      _flash = switch (_flash) {
        FlashMode.off => FlashMode.auto,
        FlashMode.auto => FlashMode.always,
        _ => FlashMode.off,
      };
    });
    _controller?.setFlashMode(_flash);
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await _initController(_cameras[_cameraIndex]);
  }

  Future<void> _setZoom(double target) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final z = target.clamp(_minZoom, _maxZoom);
    await controller.setZoomLevel(z);
    if (mounted) setState(() => _zoom = z);
  }

  Future<void> _focusAt(TapUpDetails details, BoxConstraints box) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final local = details.localPosition;
    final normalized = Offset(
      (local.dx / box.maxWidth).clamp(0.0, 1.0),
      (local.dy / box.maxHeight).clamp(0.0, 1.0),
    );
    try {
      await controller.setFocusPoint(normalized);
      await controller.setExposurePoint(normalized);
    } on CameraException {
      // Some devices/lenses don't support point focus — ignore.
    }
    setState(() => _focusPoint = local);
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _focusPoint = null);
    });
  }

  Future<void> _switchMoment() async {
    final moments = ref.read(visibleMomentsProvider);
    final chosen = await showModalBottomSheet<Moment>(
      context: context,
      backgroundColor: AppTheme.paper,
      builder: (_) => _CameraMomentSheet(moments: moments),
    );
    if (chosen == null) return;
    // Remember this pick so every later camera open defaults to it (no re-prompt).
    await ref.read(activeMomentCodeProvider.notifier).setActive(chosen.code);
    if (!mounted) return;
    setState(() {
      _momentCode = chosen.code;
      _momentName = chosen.title;
    });
  }

  IconData get _flashIcon => switch (_flash) {
        FlashMode.off => Icons.flash_off_rounded,
        FlashMode.auto => Icons.flash_auto_rounded,
        _ => Icons.flash_on_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    // System back / back-gesture must do exactly what Close (X) does, via
    // _close(): land on the relevant moment for an in-app launch, or exit to the
    // launcher for a standalone shortcut launch — never a default pop.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Viewfinder / fallback — fills the screen, tap to focus.
          if (_permissionDenied)
            const _PermissionFallback()
          else if (_initFailed)
            const _Centered(text: 'Camera unavailable')
          else if (ready)
            LayoutBuilder(
              builder: (context, box) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _focusAt(d, box),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.previewSize?.height ?? 1,
                        height: controller.value.previewSize?.width ?? 1,
                        child: CameraPreview(controller),
                      ),
                    ),
                    if (_focusPoint != null) _FocusReticle(at: _focusPoint!),
                  ],
                ),
              ),
            )
          else
            const _Centered(text: 'Starting camera…'),

          // White flash on capture.
          if (_flashOverlay) const ColoredBox(color: Colors.white),

          // Controls.
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  momentName: _momentName,
                  hasMoment: _momentCode != null,
                  flashIcon: _flashIcon,
                  shake: _shake,
                  onClose: _close,
                  onMoment: _switchMoment,
                  onFlash: _cycleFlash,
                ),
                const Spacer(),
                if (_shotCount > 0) _ShotCounter(count: _shotCount),
                const SizedBox(height: 14),
                if (ready) _ZoomRow(current: _zoom, onPick: _setZoom),
                const SizedBox(height: 12),
                const _ModeStrip(),
                const SizedBox(height: 14),
                _BottomBar(
                  lastThumbPath: _lastThumbPath,
                  shotCount: _shotCount,
                  canFlip: _cameras.length > 1,
                  onShutter: ready ? _capture : null,
                  // In-app: tap recent shot → open the moment. Shortcut launch is
                  // camera-only, so the thumbnail never navigates into the app.
                  onThumbTap: widget.shortcut ? null : _close,
                  onFlip: _flipCamera,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Glass round button (native-camera control treatment) ─────────────────────

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.momentName,
    required this.hasMoment,
    required this.flashIcon,
    required this.shake,
    required this.onClose,
    required this.onMoment,
    required this.onFlash,
  });

  final String momentName;
  final bool hasMoment;
  final IconData flashIcon;
  final Animation<double> shake;
  final VoidCallback onClose;
  final VoidCallback onMoment;
  final VoidCallback onFlash;

  @override
  Widget build(BuildContext context) {
    // Camera controls on the left; the (only) app element — the moment
    // selector — pinned top-right. It wobbles when capture is blocked.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _GlassButton(icon: Icons.close_rounded, onTap: onClose),
          const SizedBox(width: 10),
          _GlassButton(icon: flashIcon, onTap: onFlash),
          const Spacer(),
          AnimatedBuilder(
            animation: shake,
            builder: (context, child) {
              // Damped horizontal oscillation.
              final dx = math.sin(shake.value * math.pi * 5) *
                  10 *
                  (1 - shake.value);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: GestureDetector(
              onTap: onMoment,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: hasMoment
                      ? const LinearGradient(
                          colors: [AppTheme.coral, AppTheme.coralDeep])
                      : null,
                  color: hasMoment ? null : Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: hasMoment
                      ? null
                      : Border.all(color: AppTheme.coral, width: 1.4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(
                        momentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShotCounter extends StatelessWidget {
  const _ShotCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: AppTheme.sage, size: 8),
          const SizedBox(width: 8),
          Text(
            '$count QUEUED',
            style: AppText.mono(
                fontSize: 11, letterSpacing: 1, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ZoomRow extends StatelessWidget {
  const _ZoomRow({required this.current, required this.onPick});

  final double current;
  final ValueChanged<double> onPick;

  bool _isSelected(double stop) => (current - stop).abs() < 0.05;

  String _label(double stop) =>
      stop == stop.roundToDouble() ? '${stop.toInt()}×' : '$stop×';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final stop in _zoomStops)
            GestureDetector(
              onTap: () => onPick(stop),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _isSelected(stop) ? Colors.white : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _label(stop),
                  style: AppText.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isSelected(stop) ? Colors.black : AppTheme.amber,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeStrip extends StatelessWidget {
  const _ModeStrip();

  @override
  Widget build(BuildContext context) {
    // gang.roll is a photo-roll app — every capture flows into a moment's photo
    // grid. Video has nowhere to land and true portrait/bokeh needs hardware
    // depth APIs the camera plugin can't reach, so we ship a single honest mode
    // (PHOTO) rather than dead VIDEO/PORTRAIT labels. The lone active marker
    // keeps the stock-camera rhythm without faking modes that don't work.
    return Text(
      'PHOTO',
      style: AppText.mono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: AppTheme.amber,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.lastThumbPath,
    required this.shotCount,
    required this.canFlip,
    required this.onShutter,
    required this.onThumbTap,
    required this.onFlip,
  });

  final String? lastThumbPath;
  final int shotCount;
  final bool canFlip;
  final VoidCallback? onShutter;

  /// Tap the recent-shot thumbnail → open the relevant moment. Null in a
  /// shortcut launch, where the thumbnail must not navigate into the app.
  final VoidCallback? onThumbTap;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: lastThumbPath == null
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: onThumbTap,
                    child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(lastThumbPath!),
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (shotCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppTheme.coral,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$shotCount',
                              style: AppText.mono(
                                  fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          ),
          _ShutterButton(onTap: onShutter),
          _GlassButton(icon: Icons.flip_camera_ios_rounded,
              onTap: canFlip ? onFlip : () {}),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatefulWidget {
  const _ShutterButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled ? Colors.white : Colors.white38,
              width: 4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _down
                    ? Colors.white60
                    : (enabled ? Colors.white : Colors.white38),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusReticle extends StatelessWidget {
  const _FocusReticle({required this.at});

  final Offset at;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx - 36,
      top: at.dy - 36,
      child: IgnorePointer(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.amber, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: AppText.mono(fontSize: 12, color: Colors.white54),
      ),
    );
  }
}

class _PermissionFallback extends StatelessWidget {
  const _PermissionFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded,
                color: Colors.white54, size: 40),
            const SizedBox(height: 16),
            Text(
              'Camera permission required',
              textAlign: TextAlign.center,
              style: AppText.display(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable camera access in device settings to use Quick Shoot.',
              textAlign: TextAlign.center,
              style: AppText.mono(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraMomentSheet extends StatelessWidget {
  const _CameraMomentSheet({required this.moments});

  final List<Moment> moments;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shoot into…', style: AppText.display(fontSize: 20)),
            const SizedBox(height: 12),
            if (moments.isEmpty)
              Text('Create or join a moment first.',
                  style: Theme.of(context).textTheme.bodyMedium)
            else
              for (final m in moments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.circle, color: AppTheme.coral, size: 12),
                  title: Text(m.title, style: AppText.display(fontSize: 16)),
                  onTap: () => Navigator.of(context).pop(m),
                ),
          ],
        ),
      ),
    );
  }
}
