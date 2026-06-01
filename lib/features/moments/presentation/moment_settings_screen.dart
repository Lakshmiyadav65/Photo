// Screen 5 · Moment Settings — grouped cards (name, cover, dates, pin), custom
// coral toggles for notifications, and a restrained danger zone. Archive /
// Delete are gated to the host; members see a "Leave roll" action instead.
// State mutations flow through MomentsNotifier so the dashboard reacts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/app_toggle.dart';
import '../data/mock_moments.dart';
import '../domain/moment.dart';
import 'widgets/photo_thumb.dart';

const _kCurrentUser = 'Aarav';

class MomentSettingsScreen extends ConsumerStatefulWidget {
  const MomentSettingsScreen({super.key, required this.code});

  final String code;

  @override
  ConsumerState<MomentSettingsScreen> createState() =>
      _MomentSettingsScreenState();
}

class _MomentSettingsScreenState extends ConsumerState<MomentSettingsScreen> {
  bool _pinToTop = true;
  bool _muteUploads = false;
  bool _muteJoins = false;

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = true,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.paper,
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        content: Text(body, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor:
                  destructive ? AppTheme.coralDeep : AppTheme.ink,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _delete(Moment moment) async {
    final ok = await _confirm(
      title: 'Delete this moment?',
      body:
          'This permanently removes "${moment.title}" and its photos for everyone.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    ref.read(momentsProvider.notifier).remove(moment.code);
    if (mounted) context.go('/home');
  }

  Future<void> _archive(Moment moment) async {
    final ok = await _confirm(
      title: 'Archive this moment?',
      body:
          '"${moment.title}" leaves your dashboard but the photos are kept and can be restored later.',
      confirmLabel: 'Archive',
      destructive: false,
    );
    if (!ok || !mounted) return;
    ref.read(momentsProvider.notifier).archive(moment.code);
    if (mounted) context.go('/home');
  }

  Future<void> _leave(Moment moment) async {
    final ok = await _confirm(
      title: 'Leave this moment?',
      body:
          'You\'ll lose access to "${moment.title}". Photos you uploaded stay in the moment.',
      confirmLabel: 'Leave',
    );
    if (!ok || !mounted) return;
    ref.read(momentsProvider.notifier).leave(moment.code);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final moment = ref.watch(momentByCodeProvider(widget.code));
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
    final dates =
        '${DateFormat('MMM d').format(moment.endsAt ?? moment.developedAt ?? DateTime.now())}'
        '${moment.developedAt != null ? " – ${DateFormat('d').format(moment.developedAt!)}" : ""}';

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  Text('MOMENT', style: AppText.label(fontSize: 11)),
                  const SizedBox(height: 10),
                  _GroupCard(children: [
                    _NavRow(
                      label: 'Name',
                      value: moment.title,
                      onTap: () => _toast('Renaming coming soon'),
                    ),
                    const _RowDivider(),
                    _NavRow(
                      label: 'Cover',
                      trailing: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                            width: 34, height: 24, child: PhotoThumb(id: moment.code)),
                      ),
                      onTap: () => _toast('Cover picker coming soon'),
                    ),
                    const _RowDivider(),
                    _NavRow(
                      label: 'Dates',
                      value: dates,
                      onTap: () => _toast('Date editing coming soon'),
                    ),
                    const _RowDivider(),
                    _ToggleRow(
                      label: 'Pin to top',
                      value: _pinToTop,
                      onChanged: (v) => setState(() => _pinToTop = v),
                    ),
                  ]),
                  const SizedBox(height: 26),
                  Text('NOTIFICATIONS', style: AppText.label(fontSize: 11)),
                  const SizedBox(height: 10),
                  _GroupCard(children: [
                    _ToggleRow(
                      label: 'Mute uploads',
                      value: _muteUploads,
                      onChanged: (v) => setState(() => _muteUploads = v),
                    ),
                    const _RowDivider(),
                    _ToggleRow(
                      label: 'Mute joins',
                      value: _muteJoins,
                      onChanged: (v) => setState(() => _muteJoins = v),
                    ),
                  ]),
                  const SizedBox(height: 26),
                  if (moment.hostName == _kCurrentUser) ...[
                    _GroupCard(children: [
                      _DangerRow(
                        label: 'Archive moment',
                        onTap: () => _archive(moment),
                      ),
                      const _RowDivider(),
                      _DangerRow(
                        label: 'Delete moment',
                        onTap: () => _delete(moment),
                      ),
                    ]),
                  ] else ...[
                    _GroupCard(children: [
                      _DangerRow(
                        label: 'Leave moment',
                        onTap: () => _leave(moment),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.ink,
          ),
          Expanded(
            child: Center(
              child: Text('moment settings', style: AppText.display(fontSize: 17)),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, indent: 16, color: AppTheme.line2);
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.label, this.value, this.trailing, this.onTap});

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleMedium),
            ),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.muted),
                ),
              ),
            ?trailing,
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          AppToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppTheme.coralDeep),
        ),
      ),
    );
  }
}
