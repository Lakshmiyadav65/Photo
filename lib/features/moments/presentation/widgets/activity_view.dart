// The roll's activity feed — the in-app stand-in for push notifications. Opens
// as a bottom sheet from the gallery bell; lists who joined, who added shots,
// and when the roll started, newest first.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/gang_avatar.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/activity_providers.dart';
import '../../domain/activity.dart';
import 'sheet_scaffold.dart';

Future<void> showActivitySheet(BuildContext context, String code) {
  return showAppSheet(context, ActivityView(code: code));
}

String _ago(DateTime t) {
  if (t.millisecondsSinceEpoch <= 0) return '';
  final d = DateTime.now().difference(t);
  if (d.inDays >= 1) return '${d.inDays}d';
  if (d.inHours >= 1) return '${d.inHours}h';
  if (d.inMinutes >= 1) return '${d.inMinutes}m';
  return 'now';
}

class ActivityView extends ConsumerWidget {
  const ActivityView({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(momentActivityProvider(code));
    final myUid = ref.watch(authStateProvider).value?.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text('Activity', style: AppText.display(fontSize: 24))),
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded),
              color: AppTheme.muted,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Nothing here yet.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          )
        else
          for (final a in activities)
            _ActivityRow(activity: a, isMe: a.actorId == myUid),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.isMe});

  final Activity activity;
  final bool isMe;

  String get _verb => switch (activity.type) {
        ActivityType.created => 'started the roll',
        ActivityType.joined => 'joined',
        ActivityType.uploaded => 'added a shot',
        ActivityType.unknown => 'did something',
      };

  @override
  Widget build(BuildContext context) {
    final name = isMe ? 'You' : activity.actorName;
    final ago = _ago(activity.at);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          GangAvatar(name: activity.actorName, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' $_verb'),
                ],
              ),
            ),
          ),
          if (ago.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(ago, style: AppText.mono(fontSize: 11, color: AppTheme.muted)),
          ],
        ],
      ),
    );
  }
}
