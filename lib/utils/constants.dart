class AppConstants {
  // MQTT Configuration
  static const String mqttBrokerUrl = 'broker.hivemq.com';
  static const int mqttPort = 1883;
  static const String mqttClientId = 'iot_dashboard_client';

  // API Configuration
  static const String apiBaseUrl = 'https://api.example.com';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Topics
  static const String sensorDataTopic = 'iot/sensors/data';
  static const String deviceStatusTopic = 'iot/devices/status';

  // Device Types
  static const String temperatureSensor = 'temperature';
  static const String humiditySensor = 'humidity';
  static const String pressureSensor = 'pressure';
  static const String motionSensor = 'motion';

  // Update Intervals
  static const Duration sensorUpdateInterval = Duration(seconds: 5);
  static const Duration chartUpdateInterval = Duration(minutes: 1);

  // UI Constants
  static const double cardElevation = 4.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;

  // Chart Configuration
  static const int maxDataPoints = 100;
  static const double chartHeight = 200.0;

  // Storage Keys
  static const String devicesKey = 'devices';
  static const String settingsKey = 'settings';
  static const String lastSyncKey = 'last_sync';
}
