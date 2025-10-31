import '../models/device.dart';
import '../models/sensor_data.dart';

class IoTState {
  final List<Device> devices;
  final List<SensorData> sensorData;
  final Map<String, List<SensorData>> deviceSensorData;
  final bool isLoading;
  final String connectionStatus;

  const IoTState({
    this.devices = const [],
    this.sensorData = const [],
    this.deviceSensorData = const {},
    this.isLoading = false,
    this.connectionStatus = 'Disconnected',
  });

  IoTState copyWith({
    List<Device>? devices,
    List<SensorData>? sensorData,
    Map<String, List<SensorData>>? deviceSensorData,
    bool? isLoading,
    String? connectionStatus,
  }) {
    return IoTState(
      devices: devices ?? this.devices,
      sensorData: sensorData ?? this.sensorData,
      deviceSensorData: deviceSensorData ?? this.deviceSensorData,
      isLoading: isLoading ?? this.isLoading,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }

  // Computed properties
  List<Device> get onlineDevices =>
      devices.where((device) => device.isOnline).toList();
  List<Device> get offlineDevices =>
      devices.where((device) => !device.isOnline).toList();

  int get totalDevices => devices.length;
  int get activeDevices => onlineDevices.length;
  double get systemUptime => _calculateSystemUptime();

  SensorData? getLatestSensorData(String deviceId) {
    final deviceData = deviceSensorData[deviceId];
    return deviceData?.isNotEmpty == true ? deviceData!.last : null;
  }

  List<SensorData> getSensorDataForDevice(String deviceId, {int? limit}) {
    final deviceData = deviceSensorData[deviceId];
    if (deviceData == null) return [];

    final data = deviceData;
    if (limit != null && data.length > limit) {
      return data.sublist(data.length - limit);
    }
    return data;
  }

  Map<String, dynamic> getDeviceStats(String deviceId) {
    final deviceData = deviceSensorData[deviceId];
    if (deviceData == null || deviceData.isEmpty) {
      return {'count': 0, 'latest': null};
    }

    return {
      'count': deviceData.length,
      'latest': deviceData.last,
      'average': _calculateAverage(deviceData),
      'min': _findMin(deviceData),
      'max': _findMax(deviceData),
    };
  }

  double _calculateAverage(List<SensorData> data) {
    if (data.isEmpty) return 0.0;
    final sum = data.map((d) => d.value).reduce((a, b) => a + b);
    return sum / data.length;
  }

  SensorData? _findMin(List<SensorData> data) {
    if (data.isEmpty) return null;
    return data.reduce((a, b) => a.value < b.value ? a : b);
  }

  SensorData? _findMax(List<SensorData> data) {
    if (data.isEmpty) return null;
    return data.reduce((a, b) => a.value > b.value ? a : b);
  }

  double _calculateSystemUptime() {
    if (devices.isEmpty) return 0.0;

    final totalDevices = devices.length;
    final onlineDevices = this.onlineDevices.length;

    return (onlineDevices / totalDevices) * 100;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IoTState &&
          runtimeType == other.runtimeType &&
          devices == other.devices &&
          sensorData == other.sensorData &&
          deviceSensorData == other.deviceSensorData &&
          isLoading == other.isLoading &&
          connectionStatus == other.connectionStatus;

  @override
  int get hashCode =>
      devices.hashCode ^
      sensorData.hashCode ^
      deviceSensorData.hashCode ^
      isLoading.hashCode ^
      connectionStatus.hashCode;

  @override
  String toString() {
    return 'IoTState(devices: ${devices.length}, sensorData: ${sensorData.length}, isLoading: $isLoading, connectionStatus: $connectionStatus)';
  }
}
