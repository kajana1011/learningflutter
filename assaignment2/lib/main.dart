import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Ensure Flutter bindings are initialized before using platform channels
  // (SharedPreferences uses platform channels).
  WidgetsFlutterBinding.ensureInitialized();

  // Wrap the app with a ChangeNotifierProvider so ThemeProvider is available
  // anywhere below in the widget tree.
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// A simple ChangeNotifier that keeps theme state and persists it to disk.
class ThemeProvider extends ChangeNotifier {
  // Key used in SharedPreferences to persist the user's choice.
  static const _key = 'isDark';

  // Internal boolean state. Defaults to false (light theme).
  bool _isDark = false;

  // Public getter for the current state.
  bool get isDark => _isDark;

  // Convert boolean state to ThemeMode for MaterialApp.themeMode.
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  // On construction, load persisted value (if any).
  ThemeProvider() {
    _loadFromPrefs();
  }

  // Loads the saved preference from SharedPreferences asynchronously.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // If no value saved yet, default to false.
    _isDark = prefs.getBool(_key) ?? false;
    // Notify listeners so the UI updates after the async load completes.
    notifyListeners();
  }

  // Toggle theme and persist the choice.
  Future<void> toggle(bool value) async {
    _isDark = value;
    // Notify widgets that listen to this provider so they rebuild.
    notifyListeners();

    // Persist the new value so it survives app restarts.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

// Root widget of the app. Uses Consumer to listen to ThemeProvider.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer subscribes to ThemeProvider and rebuilds when it changes.
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        return MaterialApp(
          // Browser/tab title and app title.
          title: 'digitalmask.com.tz',

          // Remove the "debug" banner shown in debug mode.
          debugShowCheckedModeBanner: false,

          // Light theme settings. We use appBarTheme so AppBar colors
          // follow the app theme (instead of hard-coding colors in AppBar).
          theme: ThemeData.light().copyWith(
            appBarTheme: const AppBarTheme(backgroundColor: Color.fromARGB(255, 248, 226, 226)),
          ),

          // Dark theme settings.
          darkTheme: ThemeData.dark().copyWith(
            appBarTheme:
                const AppBarTheme(backgroundColor: Color.fromARGB(255, 36, 34, 35)),
          ),

          // Switch between light and dark based on provider state.
          themeMode: theme.themeMode,

          // The first screen shown in the app.
          home: const HomePage(),
        );
      },
    );
  }
}

// Simple home screen with a settings icon in the AppBar.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar automatically uses colors from ThemeData.appBarTheme.
      appBar: AppBar(
        title: const Text('Home'),
        // Place the settings button at the right-most side of the AppBar.
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      // Centered content with larger "Welcome" text.
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Increased font size for visibility.
          const Text('Welcome', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// Settings screen that shows the theme toggle.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use context.watch to get the current ThemeProvider and subscribe to updates.
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          // Padding to put the row just below the AppBar.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Column allows two lines of text stacked vertically.
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary label.
                    Text('Dark Theme'),
                    SizedBox(height: 4),

                    // Secondary description with smaller grey text.
                    Text(
                      'Toggle light/dark theme',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                // Spacer pushes the switch to the far right.
                const Spacer(),

                // Switch shows current theme state and calls ThemeProvider.toggle.
                Switch(value: theme.isDark, onChanged: (v) { theme.toggle(v); }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

