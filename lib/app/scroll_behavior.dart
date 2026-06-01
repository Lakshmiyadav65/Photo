// App-wide scroll behavior: scrolling stops cleanly at the edges — no iOS
// rubber-band bounce, no Android stretch/glow, no content deformation. Set once
// on MaterialApp.router so every scrollable (lists, grids, sheets, page views,
// nested containers) inherits it unless it opts out with its own physics.

import 'package:flutter/material.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  // Strip the overscroll affordance entirely (kills the Android 12+ stretch and
  // the legacy glow). Reaching an edge simply does nothing.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;

  // Clamp on every platform so nothing bounces past the content bounds.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
