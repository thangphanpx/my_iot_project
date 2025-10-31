import 'dart:async';
import '../interfaces/connection_interface.dart';
import '../../services/mqtt_service.dart';

/// Connection repository implementing the connection interface
/// Following Interface Segregation and Dependency Inversion principles
class ConnectionRepository implements ConnectionInterface {
  final MQTTService _mqttService;

  // Stream controllers for reactive updates
  final StreamController<String> _connectionStatusController =
      StreamController<String>.broadcast();
  final StreamController<void> _connectivityChangesController =
      StreamController<void>.broadcast();

  ConnectionRepository(this._mqttService) {
    // Listen to MQTT connection status updates and reflect in the streams
    _mqttService.connectionStatusStream.listen((status) {
      _connectionStatusController.add(status);
    });
  }

  @override
  Future<void> initialize() async {
    await _mqttService.initialize();
    // Connection status will be updated via stream subscription
  }

  @override
  Future<void> disconnect() async {
    _mqttService.disconnect();
    // Connection status will be updated via stream subscription
  }

  @override
  bool get isConnected => _mqttService.isConnected;

  @override
  String get connectionStatus => _mqttService.isConnected
      ? 'Connected to MQTT broker'
      : 'Disconnected from MQTT broker';

  @override
  Stream<String> watchConnectionStatus() {
    // Emit current status immediately, then listen for changes
    _connectionStatusController.add(connectionStatus);
    return _connectionStatusController.stream;
  }

  @override
  Stream<void> watchConnectivityChanges() {
    // Emit a connectivity change event immediately
    _connectivityChangesController.add(null);
    return _connectivityChangesController.stream;
  }

  /// Reconnect to the MQTT broker
  Future<void> reconnect() async {
    await disconnect();
    await initialize();
  }

  void dispose() {
    _connectionStatusController.close();
    _connectivityChangesController.close();
  }
}
