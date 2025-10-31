import '../../models/device.dart';

/// Repository interface for device data operations
/// Following Dependency Inversion Principle (DIP)
abstract class DeviceRepositoryInterface {
  Future<List<Device>> getDevices();
  Future<Device> createDevice(Device device);
  Future<Device> updateDevice(String id, Device device);
  Future<void> deleteDevice(String id);
  Stream<List<Device>> watchDevices();
}
