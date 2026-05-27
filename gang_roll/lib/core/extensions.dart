// Small extensions on common types. Add sparingly — only when the extension
// genuinely reads better than a free function or static helper.

import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  /// Shortcut for `Theme.of(context)`.
  ThemeData get theme => Theme.of(this);

  /// Shortcut for `Theme.of(context).colorScheme`.
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Shortcut for `Theme.of(context).textTheme`.
  TextTheme get text => Theme.of(this).textTheme;

  /// Shortcut for `MediaQuery.of(context).size`.
  Size get screenSize => MediaQuery.sizeOf(this);
}
