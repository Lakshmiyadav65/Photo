// A gang in the list: overlapping avatars, the gang name (serif italic, the
// app's content-title treatment), a muted people · moments meta line, and a soft
// chevron. Built on PressCard for the shared tactile press-scale + haptic. The
// avatar stack carries a Hero tag so it flies into the detail header.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme.dart';
import '../../../moments/presentation/widgets/avatar_stack.dart';
import '../../../moments/presentation/widgets/press_card.dart';
import '../../domain/gang.dart';

/// Shared Hero tag for a gang's avatar stack across list → detail.
String gangAvatarHeroTag(String id) => 'gang-avatars-$id';

class GangCard extends StatelessWidget {
  const GangCard({super.key, required this.gang, required this.onTap});

  final Gang gang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Hero(
            tag: gangAvatarHeroTag(gang.id),
            child: AvatarStack(
              names: gang.members,
              size: 36,
              max: 3,
              borderColor: AppTheme.paper,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        gang.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    // Muted indicator.
                    if (gang.muted) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.notifications_off_rounded,
                          size: 14, color: AppTheme.muted),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${gang.peopleCount} PEOPLE · ${gang.momentCount} MOMENTS',
                  style: AppText.label(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
        ],
      ),
    );
  }
}
