import 'dart:async';
import '../../models/sensor_data.dart';
import '../../models/sensor_data.dart' show SensorType;
import '../interfaces/sensor_repository_interface.dart';
import '../../services/api_service.dart';
import '../../services/mqtt_service.dart';

/// Sensor repository implementing the repository interface
/// Following Interface Segregation and Dependency Inversion principles
class SensorRepository implements SensorRepositoryInterface {
  final ApiService _apiService;
  final MQTTService _mqttService;

  // Stream controllers for reactive updates
  final StreamController<List<SensorData>> _deviceSensorDataController =
      StreamController<List<SensorData>>.broadcast();
  final StreamController<SensorData> _latestSensorDataController =
      StreamController<SensorData>.broadcast();

  SensorRepository(this._apiService, this._mqttService) {
    // Listen to MQTT sensor data updates and reflect in the streams
    _mqttService.sensorDataStream.listen(_handleNewSensorData);
  }

  void _handleNewSensorData(SensorData sensorData) {
    // Emit latest sensor data for all listeners
    _latestSensorDataController.add(sensorData);

    // Also emit to device-specific stream (this is a simplified implementation)
    // In a real app, you'd want to cache and manage device-specific streams more efficiently
    _deviceSensorDataController.add([sensorData]);
  }

  @override
  Future<List<SensorData>> getSensorData(String deviceId, {int? limit}) async {
    // Use the API service to get sensor data
    return await _apiService.getSensorData(deviceId: deviceId, limit: limit);
  }

  @override
  Stream<List<SensorData>> watchSensorData(String deviceId) {
    // Initialize with current data
    _getSensorDataAndEmit(deviceId);

    // Return the device-specific stream
    // Note: In a production app, you'd want device-specific streams
    return _deviceSensorDataController.stream;
  }

  @override
  Stream<SensorData> watchLatestSensorData(String deviceId) {
    // For now, return the general latest sensor data stream
    // In a production app, you'd filter by deviceId
    return _latestSensorDataController.stream;
  }

  Future<void> _getSensorDataAndEmit(String deviceId) async {
    try {
      final sensorData = await _apiService.getSensorData(deviceId: deviceId);
      _deviceSensorDataController.add(sensorData);
    } catch (e) {
      // Error handling is delegated to the state management layer
      print('Error refreshing sensor data in repository: $e');
    }
  }

  @override
  Future<void> sendSensorData(SensorData sensorData) async {
    try {
      // Send to API
      await _apiService.sendSensorData(sensorData);

      // Also publish to MQTT if connected
      if (_mqttService.isConnected) {
        await _mqttService.publishSensorData(sensorData);
      }
    } catch (e) {
      print('Error sending sensor data: $e');
      rethrow;
    }
  }

  /// Send sensor data for a specific device (legacy method for compatibility)
  Future<void> sendSensorDataForDevice(String deviceId, double value) async {
    final sensorData = SensorData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deviceId: deviceId,
      type: SensorType.temperature,
      value: value,
      timestamp: DateTime.now(),
      unit: '°C',
    );

    await sendSensorData(sensorData);
  }

  void dispose() {
    _deviceSensorDataController.close();
    _latestSensorDataController.close();
  }
}
