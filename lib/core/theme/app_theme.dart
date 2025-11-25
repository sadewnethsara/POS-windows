import 'package:fluent_ui/fluent_ui.dart';

class AppTheme {
  static FluentThemeData getTheme(Brightness brightness, bool isTouchMode) {
    final baseTheme = brightness == Brightness.light ? light : dark;

    // In Touch Mode, we can adjust typography or component themes if needed.
    // For now, we'll return the base theme, but this structure allows for future scaling.
    // Fluent UI doesn't have a direct 'visualDensity' equivalent to Material,
    // so touch optimization is often done via specific widget padding adjustments
    // using the provider directly in the UI.
    return baseTheme;
  }

  static final light = FluentThemeData(
    brightness: Brightness.light,
    accentColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: Colors.grey[20],
    ),
  );

  static final dark = FluentThemeData(
    brightness: Brightness.dark,
    accentColor: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[160],
    cardColor: Colors.grey[150],
    navigationPaneTheme: NavigationPaneThemeData(
      backgroundColor: Colors.grey[180],
    ),
  );
}
