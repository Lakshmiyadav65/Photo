// The Members tab of a gang: each member with avatar, name (+ HOST badge for
// the founder), join month and contribution count. Mirrors the roll members
// row so the social surfaces feel like one family. Join date / contributions
// are derived deterministically until the data layer provides real figures.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/gang_avatar.dart';
import '../../domain/gang.dart';

class GangMembersList extends StatelessWidget {
  const GangMembersList({super.key, required this.gang});

  final Gang gang;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('gang-members'),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
      children: [
        for (var i = 0; i < gang.members.length; i++)
          _MemberRow(
            name: gang.members[i],
            isHost: i == 0,
            joined: _joinLabel(gang, i),
            contributions: _contributions(gang.members[i], gang),
          ),
      ],
    );
  }

  // Founder joins at creation; others trickle in over the following months.
  String _joinLabel(Gang gang, int index) {
    final date = DateTime(
      gang.createdAt.year,
      gang.createdAt.month + index,
      gang.createdAt.day,
    );
    return DateFormat('MMM yyyy').format(date);
  }

  int _contributions(String name, Gang gang) =>
      8 + (name.hashCode.abs() % (gang.momentCount * 3 + 12));
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.isHost,
    required this.joined,
    required this.contributions,
  });

  final String name;
  final bool isHost;
  final String joined;
  final int contributions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          GangAvatar(name: name, size: 42),
          const SizedBox(width: 13),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.coral,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'HOST',
                          style: AppText.mono(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('joined $joined',
                    style: AppText.mono(fontSize: 10, color: AppTheme.muted)),
              ],
            ),
          ),
          Text('$contributions shots',
              style: AppText.mono(fontSize: 11, color: AppTheme.muted)),
        ],
      ),
    );
  }
}
