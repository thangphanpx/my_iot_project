import 'package:flutter/material.dart';
import 'core/service_locator.dart';
import 'screens/dashboard_reactive_screen.dart';

void main() {
  // Initialize service locator
  serviceLocator.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Dashboard (Reactive)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const DashboardReactiveScreen(),
      // Note: In a production app, you might want to add routes for different screens
      routes: {
        '/dashboard': (context) => const DashboardReactiveScreen(),
      },
    );
  }
}
