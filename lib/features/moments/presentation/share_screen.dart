// Share · <code> — the moment invite. Cover + code + a coral "Share invite"
// button that hands the OS its native share sheet, plus a quick "Copy code"
// fallback. Per spec, we never build a custom share UI; just hand off.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../data/mock_moments.dart';
import '../domain/moment.dart';
import 'widgets/moment_cover.dart';
import 'widgets/press_card.dart';

class ShareScreen extends ConsumerWidget {
  const ShareScreen({super.key, required this.code});

  final String code;

  String get _link => 'https://gang.roll/join/$code';
  String _inviteMessage(Moment m) =>
      'Join my gang.roll for "${m.title}" — code $code · $_link';

  Future<void> _share(BuildContext context, Moment moment) async {
    final box = context.findRenderObject() as RenderBox?;
    HapticFeedback.selectionClick();
    await SharePlus.instance.share(
      ShareParams(
        text: _inviteMessage(moment),
        subject: 'You\'re invited to ${moment.title}',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ),
    );
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.selectionClick();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Moment code copied')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = ref.watch(momentByCodeProvider(code));
    if (moment == null) {
      return Scaffold(
        backgroundColor: AppTheme.cream,
        appBar: AppBar(),
        body: Center(
          child: Text('We couldn’t find that moment.',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onClose: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  // Cover preview — same cover the dashboard shows.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: MomentCover(moment: moment),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('INVITE CODE · TAP TO COPY',
                      style: AppText.label(fontSize: 10)),
                  const SizedBox(height: 10),
                  _CodeCard(code: code, onTap: () => _copyCode(context)),
                  const SizedBox(height: 22),
                  Text('OR SCAN', style: AppText.label(fontSize: 10)),
                  const SizedBox(height: 10),
                  _QrPanel(data: _link),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                style: AppTheme.coralButton,
                onPressed: () => _share(context, moment),
                child: const Text('Share invite →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppTheme.ink,
          ),
          Expanded(
            child: Center(
              child:
                  Text('invite to moment', style: AppText.display(fontSize: 17)),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      gradient: const LinearGradient(
        colors: [AppTheme.coral, AppTheme.coralDeep],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      splashColor: Colors.white.withValues(alpha: 0.12),
      boxShadow: const [
        BoxShadow(
          color: AppTheme.softShadow,
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              style: AppText.mono(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
        ],
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: Center(
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 200,
          gapless: true,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: AppTheme.ink,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: AppTheme.ink,
          ),
        ),
      ),
    );
  }
}
