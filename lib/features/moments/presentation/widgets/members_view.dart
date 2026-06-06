// The roll's members: each with avatar, name (+ HOST badge), join date and
// contribution count, plus an "Invite more" action. Used as a bottom sheet
// (from the gallery member row) and full-screen (the /members route).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/brand.dart';
import '../../../../shared/widgets/gang_avatar.dart';
import '../../domain/moment.dart';
import '../../domain/photo.dart';
import 'press_card.dart';
import 'sheet_scaffold.dart';

Future<void> showMembersSheet(
  BuildContext context,
  Moment moment,
  List<Photo> photos, {
  VoidCallback? onInvite,
}) {
  return showAppSheet(
    context,
    MembersView(moment: moment, photos: photos, onInvite: onInvite),
  );
}

class MembersView extends StatelessWidget {
  const MembersView({
    super.key,
    required this.moment,
    required this.photos,
    this.onInvite,
  });

  final Moment moment;
  final List<Photo> photos;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final p in photos) {
      counts[p.uploader] = (counts[p.uploader] ?? 0) + 1;
    }
    final joined = DateFormat('MMM d')
        .format(moment.developedAt ?? moment.endsAt ?? DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HeroTitle(
                    before: '',
                    emphasis: 'Members',
                    fontSize: 24,
                  ),
                  const SizedBox(height: 2),
                  Text('${moment.memberCount} IN THIS ROLL',
                      style: AppText.label(fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded),
              color: AppTheme.muted,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < moment.members.length; i++)
          _MemberRow(
            name: moment.members[i],
            isHost: i == 0,
            joined: joined,
            shots: counts[moment.members[i]] ?? 0,
          ),
        const SizedBox(height: 8),
        PressCard(
          onTap: () {
            Navigator.of(context).maybePop();
            onInvite?.call();
          },
          radius: AppTheme.radiusButton,
          border: Border.all(color: AppTheme.line),
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_alt_rounded,
                  size: 18, color: AppTheme.ink),
              const SizedBox(width: 10),
              Text('Invite more',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.isHost,
    required this.joined,
    required this.shots,
  });

  final String name;
  final bool isHost;
  final String joined;
  final int shots;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          GangAvatar(name: name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleMedium),
                    if (isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.coral,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('HOST',
                            style: AppText.mono(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: Colors.white,
                            )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('Joined $joined',
                    style: AppText.mono(fontSize: 10, color: AppTheme.muted)),
              ],
            ),
          ),
          Text('$shots shots',
              style: AppText.mono(fontSize: 11, color: AppTheme.muted)),
        ],
      ),
    );
  }
}
