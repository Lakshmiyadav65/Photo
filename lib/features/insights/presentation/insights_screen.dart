// Screen 3 (route form) · Moment Insights — full-screen host for [InsightsView],
// used by the home card's insights shortcut and deep links. The gallery opens
// the same view as a bottom sheet (showInsightsSheet).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../moments/data/mock_moments.dart';
import '../../moments/data/mock_photos.dart';
import '../../moments/presentation/widgets/insights_view.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key, required this.code});

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
                child: InsightsView(
                  moment: moment,
                  photos: ref.watch(momentPhotosProvider(code)),
                ),
              ),
      ),
    );
  }
}
