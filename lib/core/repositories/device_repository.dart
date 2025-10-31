import 'dart:async';
import '../../models/device.dart';
import '../interfaces/device_repository_interface.dart';
import '../../services/api_service.dart';
import '../../services/mqtt_service.dart';

/// Device repository implementing the repository interface
/// Following Interface Segregation and Dependency Inversion principles
class DeviceRepository implements DeviceRepositoryInterface {
  final ApiService _apiService;
  final MQTTService _mqttService;
  final StreamController<List<Device>> _devicesController =
      StreamController<List<Device>>.broadcast();

  DeviceRepository(this._apiService, this._mqttService) {
    // Listen to MQTT device status updates and reflect in the stream
    _mqttService.deviceStatusStream.listen(_handleDeviceUpdate);
  }

  void _handleDeviceUpdate(Device updatedDevice) {
    // When a device status is updated via MQTT, we need to refresh the device list
    // This is a simplified implementation - in a real app, you'd want more sophisticated caching
    _getDevicesAndEmit();
  }

  Future<void> _getDevicesAndEmit() async {
    try {
      final devices = await _apiService.getDevices();
      _devicesController.add(devices);
    } catch (e) {
      // Error handling is delegated to the state management layer
      print('Error refreshing devices in repository: $e');
    }
  }

  @override
  Future<List<Device>> getDevices() async {
    return await _apiService.getDevices();
  }

  @override
  Stream<List<Device>> watchDevices() {
    // Initialize with current data
    _getDevicesAndEmit();
    return _devicesController.stream;
  }

  @override
  Future<Device> createDevice(Device device) async {
    final createdDevice = await _apiService.createDevice(device);

    // Publish device creation to MQTT if connected
    if (_mqttService.isConnected) {
      await _mqttService.publishDeviceStatus(createdDevice);
    }

    // Refresh the device list
    await _getDevicesAndEmit();

    return createdDevice;
  }

  @override
  Future<Device> updateDevice(String id, Device device) async {
    final updatedDevice = await _apiService.updateDevice(id, device);

    // Publish device update to MQTT if connected
    if (_mqttService.isConnected) {
      await _mqttService.publishDeviceStatus(updatedDevice);
    }

    // Refresh the device list
    await _getDevicesAndEmit();

    return updatedDevice;
  }

  @override
  Future<void> deleteDevice(String id) async {
    await _apiService.deleteDevice(id);

    // Refresh the device list
    await _getDevicesAndEmit();
  }

  void dispose() {
    _devicesController.close();
  }
}
