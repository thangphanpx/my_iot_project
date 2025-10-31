import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../models/sensor_data.dart';
import 'iot_state.dart';
import 'iot_notifier.dart';

// Provider for IoT notifier
final iotNotifierProvider = StateNotifierProvider<IoTNotifier, IoTState>((ref) {
  return IoTNotifier();
});

// Convenience providers for state properties
final devicesProvider = Provider<List<Device>>((ref) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.devices;
});

final sensorDataProvider = Provider<List<SensorData>>((ref) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.sensorData;
});

final deviceSensorDataProvider = Provider<Map<String, List<SensorData>>>((ref) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.deviceSensorData;
});

final isLoadingProvider = Provider<bool>((ref) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.isLoading;
});

final connectionStatusProvider = Provider<String>((ref) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.connectionStatus;
});

final onlineDevicesProvider = Provider<List<Device>>((ref) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.onlineDevices;
});

final offlineDevicesProvider = Provider<List<Device>>((ref) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.offlineDevices;
});

final totalDevicesProvider = Provider<int>((ref) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.totalDevices;
});

final activeDevicesProvider = Provider<int>((ref) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.activeDevices;
});

final systemUptimeProvider = Provider<double>((ref) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.systemUptime;
});

// Method providers (these call methods on the notifier)
final refreshDevicesProvider = Provider<Future<void> Function()?>((ref) {
  final notifier = ref.read(iotNotifierProvider.notifier);
  return notifier.refreshDevices;
});

final addDeviceProvider = Provider<Future<void> Function(Device)>((ref) {
  final notifier = ref.read(iotNotifierProvider.notifier);
  return notifier.addDevice;
});

final updateDeviceProvider =
    Provider<Future<void> Function(String, Device)>((ref) {
  final notifier = ref.read(iotNotifierProvider.notifier);
  return notifier.updateDevice;
});

final deleteDeviceProvider = Provider<Future<void> Function(String)>((ref) {
  final notifier = ref.read(iotNotifierProvider.notifier);
  return notifier.deleteDevice;
});

final controlDeviceProvider =
    Provider<Future<void> Function(String, Map<String, dynamic>)>((ref) {
  final notifier = ref.read(iotNotifierProvider.notifier);
  return notifier.controlDevice;
});

final reconnectMQTTProvider = Provider<Future<void> Function()?>((ref) {
  final notifier = ref.read(iotNotifierProvider.notifier);
  return notifier.reconnectMQTT;
});

// Utility providers for getting specific device data
final deviceLatestSensorDataProvider =
    Provider.family<SensorData?, String>((ref, deviceId) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.getLatestSensorData(deviceId);
});

final deviceSensorDataForDeviceProvider =
    Provider.family<List<SensorData>, String>((ref, deviceId) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.getSensorDataForDevice(deviceId);
});

final deviceStatsProvider =
    Provider.family<Map<String, dynamic>, String>((ref, deviceId) {
  final iotState = ref.watch(iotNotifierProvider);
  return iotState.getDeviceStats(deviceId);
});
