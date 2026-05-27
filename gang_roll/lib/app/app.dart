// Root widget. Owns MaterialApp.router, theme, and the GoRouter instance.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class GangRollApp extends ConsumerWidget {
  const GangRollApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'gang.roll',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Light mode only in v1 per spec.
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
