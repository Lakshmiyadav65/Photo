// Screen 4 (route form) · Members — full-screen host for [MembersView]. The
// gallery opens the same view as a bottom sheet (showMembersSheet).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../data/mock_moments.dart';
import '../data/mock_photos.dart';
import 'widgets/members_view.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moment = ref.watch(momentByCodeProvider(code));
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: moment == null
            ? Center(
                child: Text('We couldn’t find that moment.',
                    style: Theme.of(context).textTheme.bodyMedium),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: MembersView(
                  moment: moment,
                  photos: ref.watch(momentPhotosProvider(code)),
                  onInvite: () => context.push('/moment/$code/share'),
                ),
              ),
      ),
    );
  }
}
