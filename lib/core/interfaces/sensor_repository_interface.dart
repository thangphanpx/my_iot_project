import '../../models/sensor_data.dart';

/// Repository interface for sensor data operations
/// Following Dependency Inversion Principle (DIP)
abstract class SensorRepositoryInterface {
  Future<List<SensorData>> getSensorData(String deviceId, {int? limit});
  Future<void> sendSensorData(SensorData sensorData);
  Stream<List<SensorData>> watchSensorData(String deviceId);
  Stream<SensorData> watchLatestSensorData(String deviceId);
}
