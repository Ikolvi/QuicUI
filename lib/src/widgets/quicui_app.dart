/// QuicUI application root widget and Material app configuration
///
/// This module provides the main application widget that wraps the entire
/// QuicUI application with Material Design theme and navigation support.
///
/// ## Widget Hierarchy
///
/// ```
/// QuicUIApp (Entry point)
///   └→ MaterialApp (Material Design wrapper)
///        ├→ Title, Theme configuration
///        └→ Home widget (content area)
/// ```
///
/// ## Usage Examples
///
/// ### Basic Application Setup
/// ```dart
/// void main() {
///   runApp(
///     QuicUIApp(
///       title: 'My App',
///       home: HomeScreen(),
///     ),
///   );
/// }
/// ```
///
/// ### Custom Theme
/// ```dart
/// final customTheme = ThemeData(
///   primarySwatch: Colors.purple,
///   useMaterial3: true,
/// );
///
/// QuicUIApp(
///   title: 'Themed App',
///   theme: customTheme,
///   home: MyHomePage(),
/// )
/// ```
///
/// ### Default Configuration
/// ```dart
/// // Using all defaults
/// QuicUIApp(
///   home: Dashboard(),
/// )
/// // Results in: title='QuicUI', theme=blue primary
/// ```
///
/// ## Architecture
///
/// Acts as the root MaterialApp widget:
/// - **Stateless**: Immutable widget (theme and home don't change after creation)
/// - **Material Design**: All widgets inherit Material theme
/// - **Navigation-ready**: Works with Material navigation (Navigator, Routes)
/// - **Theme support**: Custom or default Material theme
///
/// ## Configuration Options
///
/// | Parameter | Type | Default | Purpose |
/// |-----------|------|---------|---------|
/// | title | String | 'QuicUI' | Browser/task switcher title |
/// | theme | ThemeData | Blue primary | Material design theme |
/// | home | Widget | Placeholder | Initial screen to display |
///
/// ## Best Practices
///
/// - **Initialize at main()**: Should be the root widget in `runApp()`
/// - **Custom theme**: Provide theme for consistent branding
/// - **Home widget**: Always provide meaningful home screen
/// - **Title**: Set to app name for user recognition
///
/// ## Common Customizations
///
/// ### Dark Theme Support
/// ```dart
/// final darkTheme = ThemeData.dark().copyWith(
///   useMaterial3: true,
/// );
///
/// QuicUIApp(
///   title: 'Dark Mode App',
///   theme: darkTheme,
///   home: MyApp(),
/// )
/// ```
///
/// ### Routes Configuration
/// ```dart
/// QuicUIApp(
///   title: 'Navigation App',
///   home: NavigationHome(),
///   // Navigator.pushNamed() can now route to other screens
/// )
/// ```
///
/// ## Related Widgets
///
/// - [ScreenView]: Displays dynamically loaded screen data
/// - [MaterialApp]: Flutter's Material application wrapper (parent class)
///
/// See also:
/// - [ScreenBloc]: State management for screens
/// - [QuicUIService]: Service for loading screens


import 'package:flutter/material.dart';

/// Root application widget for QuicUI framework
///
/// This widget serves as the entry point for QuicUI applications,
/// providing Material Design theming and application-level configuration.
///
/// ## Widget Type
/// Stateless widget - immutable after creation.
/// Theme and home screen are configured once and don't change.
///
/// ## Responsibilities
/// - Wrap application with MaterialApp
/// - Apply Material Design theme
/// - Set application title
/// - Configure root navigation context
/// - Provide default home screen
///
/// ## Parameters
///
/// - [title]: Application title shown in browser/task switcher
/// - [theme]: Material Design theme (uses blue primary if not provided)
/// - [home]: Root/home widget to display (shows placeholder if not provided)
/// - [key]: Widget key for identification (optional)
///
/// ## Properties
///
/// ```dart
/// final String title;           // App title (default: 'QuicUI')
/// final ThemeData? theme;       // Material theme (default: Blue theme)
/// final Widget? home;           // Home screen (default: Placeholder)
/// ```
///
/// ## Example Usage
///
/// ### Minimal Setup
/// ```dart
/// void main() {
///   runApp(
///     QuicUIApp(home: MyHomePage()),
///   );
/// }
/// ```
///
/// ### Full Configuration
/// ```dart
/// final appTheme = ThemeData(
///   primarySwatch: Colors.deepPurple,
///   useMaterial3: true,
///   fontFamily: 'Roboto',
/// );
///
/// void main() {
///   runApp(
///     QuicUIApp(
///       title: 'My QuicUI App',
///       theme: appTheme,
///       home: HomeScreen(),
///     ),
///   );
/// }
/// ```
///
/// ### BLoC Integration
/// ```dart
/// void main() {
///   runApp(
///     MultiBlocProvider(
///       providers: [
///         BlocProvider(create: (_) => ScreenBloc(repository)),
///       ],
///       child: QuicUIApp(
///         title: 'QuicUI with BLoC',
///         home: ScreenContainer(),
///       ),
///     ),
///   );
/// }
/// ```
///
/// ## Build Method
///
/// Returns MaterialApp with:
/// - Application title for system identification
/// - Theme from parameter or default blue theme
/// - Home widget from parameter or placeholder
///
/// ## Default Theme
/// If no theme provided, creates basic Material theme with blue primary swatch.
/// Suitable for development but should be customized for production.
///
/// ## Default Home
/// If no home provided, shows placeholder Scaffold with centered text.
/// Useful for testing, but home should be specified in real apps.
///
/// ## Navigation Support
/// Works with Flutter's Material navigation:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => NextScreen(),
/// ));
/// ```
///
/// ## State Management Integration
/// Can be wrapped with BLoC providers:
/// ```dart
/// BlocProvider(
///   create: (_) => ScreenBloc(),
///   child: QuicUIApp(home: ScreenPage()),
/// )
/// ```
///
/// ## Lifecycle
/// 1. App instantiated with configuration
/// 2. build() called to create MaterialApp
/// 3. MaterialApp initializes theme and home
/// 4. Home widget displays and navigation begins
/// 5. Remains for lifetime of application
///
/// See also:
/// - [ScreenView]: For displaying individual screens
/// - [MaterialApp]: Parent class providing Material Design
class QuicUIApp extends StatelessWidget {
  /// Application title shown in browser/task switcher
  ///
  /// Used by the operating system for identification and display
  /// in window manager/task switcher.
  ///
  /// Default: 'QuicUI'
  final String title;

  /// Material Design theme for the application
  ///
  /// Defines colors, typography, and styling for all Material widgets.
  /// If not provided, a basic theme with blue primary swatch is used.
  ///
  /// ## Common Customizations
  /// ```dart
  /// ThemeData(
  ///   primarySwatch: Colors.purple,
  ///   useMaterial3: true,
  ///   fontFamily: 'CustomFont',
  /// )
  /// ```
  ///
  /// Default: Blue primary swatch theme
  final ThemeData? theme;

  /// Root/home widget displayed when app launches
  ///
  /// First screen shown to user. If not provided, shows placeholder
  /// Scaffold with centered text.
  ///
  /// Typically a screen or navigation widget like:
  /// - HomeScreen
  /// - NavigationShell
  /// - SplashScreen
  ///
  /// Default: Placeholder Scaffold
  final Widget? home;

  /// Creates a new QuicUI application widget
  ///
  /// ## Parameters
  /// - [key]: Optional widget key for identification
  /// - [title]: Application title (default: 'QuicUI')
  /// - [theme]: Material theme (default: blue primary theme)
  /// - [home]: Home screen widget (default: placeholder)
  ///
  /// ## Example
  /// ```dart
  /// const app = QuicUIApp(
  ///   title: 'My App',
  ///   theme: myCustomTheme,
  ///   home: HomePage(),
  /// );
  /// ```
  const QuicUIApp({
    Key? key,
    this.title = 'QuicUI',
    this.theme,
    this.home,
  }) : super(key: key);

  /// Build the Material application widget
  ///
  /// Constructs MaterialApp with configured title, theme, and home screen.
  ///
  /// ## Build Process
  /// 1. Takes MaterialApp template
  /// 2. Applies configured title
  /// 3. Applies theme (custom or default blue)
  /// 4. Applies home screen (custom or placeholder)
  /// 5. Returns configured MaterialApp
  ///
  /// ## Returns
  /// MaterialApp: Root application widget
  ///
  /// ## Example Output
  /// ```
  /// MaterialApp(
  ///   title: 'QuicUI',
  ///   theme: ThemeData(primarySwatch: Colors.blue),
  ///   home: Scaffold(...),
  /// )
  /// ```
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: theme ?? ThemeData(primarySwatch: Colors.blue),
      home: home ?? const Scaffold(
        body: Center(
          child: Text('QuicUI App'),
        ),
      ),
    );
  }
}
