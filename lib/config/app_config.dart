import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AppConfig {
  // MQTT Configuration
  static String get mqttBroker => AppConstants.mqttBrokerUrl;
  static int get mqttPort => AppConstants.mqttPort;
  static String get mqttClientId => AppConstants.mqttClientId;

  // API Configuration
  static String get apiBaseUrl => AppConstants.apiBaseUrl;
  static Duration get apiTimeout => AppConstants.apiTimeout;

  // MQTT Topics
  static String get sensorDataTopic => AppConstants.sensorDataTopic;
  static String get deviceStatusTopic => AppConstants.deviceStatusTopic;

  // Update Intervals
  static Duration get sensorUpdateInterval => AppConstants.sensorUpdateInterval;
  static Duration get chartUpdateInterval => AppConstants.chartUpdateInterval;

  // UI Configuration
  static double get cardElevation => AppConstants.cardElevation;
  static double get borderRadius => AppConstants.borderRadius;
  static double get iconSize => AppConstants.iconSize;

  // Chart Configuration
  static int get maxDataPoints => AppConstants.maxDataPoints;
  static double get chartHeight => AppConstants.chartHeight;

  // Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      brightness: Brightness.light,
      appBarTheme: const AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Device Configuration
  static const Map<String, String> deviceTypeIcons = {
    'temperature': '🌡️',
    'humidity': '💧',
    'pressure': '⚡',
    'motion': '👤',
    'light': '💡',
    'gas': '💨',
  };

  static const Map<String, Color> statusColors = {
    'online': Colors.green,
    'offline': Colors.grey,
    'error': Colors.red,
    'maintenance': Colors.orange,
  };

  // Storage Configuration
  static String get devicesStorageKey => AppConstants.devicesKey;
  static String get settingsStorageKey => AppConstants.settingsKey;
  static String get lastSyncStorageKey => AppConstants.lastSyncKey;

  // Validation
  static bool isValidIpAddress(String ip) {
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) return false;

    final parts = ip.split('.');
    return parts.every((part) {
      final num = int.tryParse(part);
      return num != null && num >= 0 && num <= 255;
    });
  }

  static bool isValidMacAddress(String mac) {
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return macRegex.hasMatch(mac);
  }

  static String formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  static String formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
