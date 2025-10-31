import 'dart:async';
import 'dart:collection';
import '../../models/sensor_data.dart';
import '../base/reactive_state.dart';
import '../interfaces/sensor_repository_interface.dart';

/// Sensor state management with fine-grained reactivity
/// Following Single Responsibility Principle (SRP)
class SensorState extends ReactiveState<SensorStateData> {
  final SensorRepositoryInterface _sensorRepository;
  StreamSubscription<SensorData>? _sensorDataSubscription;
  StreamSubscription<List<SensorData>>? _deviceSensorDataSubscription;

  SensorState(
    this._sensorRepository, {
    SensorStateData? initialState,
  }) : super(
          initialState ??
              const SensorStateData(
                deviceSensorData: {},
                latestSensorData: {},
                isLoading: false,
                error: null,
              ),
        ) {
    _initialize();
  }

  void _initialize() {
    // Watch for new sensor data across all devices
    _sensorDataSubscription =
        _sensorRepository.watchLatestSensorData('').listen(
      _handleNewSensorData,
      onError: (error) {
        update((current) => current.copyWith(
              error: error.toString(),
              isLoading: false,
            ));
      },
    );
  }

  void _handleNewSensorData(SensorData sensorData) {
    final deviceId = sensorData.deviceId;

    update((current) {
      final newDeviceSensorData =
          Map<String, List<SensorData>>.from(current.deviceSensorData);
      final newLatestSensorData =
          Map<String, SensorData>.from(current.latestSensorData);

      // Add to device-specific data
      if (newDeviceSensorData[deviceId] == null) {
        newDeviceSensorData[deviceId] = [];
      }

      newDeviceSensorData[deviceId]!.add(sensorData);

      // Keep only recent data points (last 1000 points per device)
      if (newDeviceSensorData[deviceId]!.length > 1000) {
        newDeviceSensorData[deviceId]!
            .removeRange(0, newDeviceSensorData[deviceId]!.length - 1000);
      }

      // Update latest sensor data
      newLatestSensorData[deviceId] = sensorData;

      return current.copyWith(
        deviceSensorData: newDeviceSensorData,
        latestSensorData: newLatestSensorData,
        isLoading: false,
        error: null,
      );
    });
  }

  /// Load sensor data for a specific device
  Future<void> loadSensorData(String deviceId, {int? limit}) async {
    update((current) => current.copyWith(isLoading: true, error: null));

    try {
      final sensorData =
          await _sensorRepository.getSensorData(deviceId, limit: limit);
      _updateDeviceSensorData(deviceId, sensorData);
    } catch (error) {
      update((current) => current.copyWith(
            error: error.toString(),
            isLoading: false,
          ));
    }
  }

  /// Watch sensor data for a specific device
  void watchSensorDataForDevice(String deviceId) {
    _deviceSensorDataSubscription?.cancel();

    _deviceSensorDataSubscription =
        _sensorRepository.watchSensorData(deviceId).listen(
      (sensorData) {
        _updateDeviceSensorData(deviceId, sensorData);
      },
      onError: (error) {
        update((current) => current.copyWith(error: error.toString()));
      },
    );
  }

  void _updateDeviceSensorData(String deviceId, List<SensorData> sensorData) {
    update((current) {
      final newDeviceSensorData =
          Map<String, List<SensorData>>.from(current.deviceSensorData);
      newDeviceSensorData[deviceId] = sensorData;

      // Update latest sensor data
      final newLatestSensorData =
          Map<String, SensorData>.from(current.latestSensorData);
      if (sensorData.isNotEmpty) {
        newLatestSensorData[deviceId] = sensorData.last;
      }

      return current.copyWith(
        deviceSensorData: newDeviceSensorData,
        latestSensorData: newLatestSensorData,
        isLoading: false,
        error: null,
      );
    });
  }

  /// Send sensor data
  Future<void> sendSensorData(SensorData sensorData) async {
    try {
      await _sensorRepository.sendSensorData(sensorData);
      // No need to manually update state - stream will notify
    } catch (error) {
      update((current) => current.copyWith(error: error.toString()));
      rethrow;
    }
  }

  /// Clear error state
  void clearError() {
    update((current) => current.copyWith(error: null));
  }

  /// Get sensor data for device
  List<SensorData> getSensorDataForDevice(String deviceId) {
    return state.deviceSensorData[deviceId] ?? [];
  }

  /// Get latest sensor data for device
  SensorData? getLatestSensorDataForDevice(String deviceId) {
    return state.latestSensorData[deviceId];
  }

  /// Get all devices with sensor data
  List<String> get devicesWithSensorData =>
      state.deviceSensorData.keys.toList();

  /// Get sensor data statistics for device
  Map<String, dynamic> getSensorStats(String deviceId) {
    final deviceData = getSensorDataForDevice(deviceId);
    if (deviceData.isEmpty) {
      return {'count': 0, 'latest': null};
    }

    final values = deviceData.map((data) => data.value).toList();
    final sum = values.reduce((a, b) => a + b);

    return {
      'count': deviceData.length,
      'latest': deviceData.last,
      'average': sum / deviceData.length,
      'min': values.reduce((a, b) => a < b ? a : b),
      'max': values.reduce((a, b) => a > b ? a : b),
    };
  }

  /// Filter sensor data by time range
  List<SensorData> getSensorDataInTimeRange(
    String deviceId,
    DateTime start,
    DateTime end,
  ) {
    return getSensorDataForDevice(deviceId)
        .where((data) =>
            data.timestamp.isAfter(start) && data.timestamp.isBefore(end))
        .toList();
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    _deviceSensorDataSubscription?.cancel();
    super.dispose();
  }
}

/// Immutable state data class for sensor data
/// Following Immutability principle
class SensorStateData {
  final Map<String, List<SensorData>> deviceSensorData;
  final Map<String, SensorData> latestSensorData;
  final bool isLoading;
  final String? error;

  const SensorStateData({
    required this.deviceSensorData,
    required this.latestSensorData,
    required this.isLoading,
    this.error,
  });

  SensorStateData copyWith({
    Map<String, List<SensorData>>? deviceSensorData,
    Map<String, SensorData>? latestSensorData,
    bool? isLoading,
    String? error,
  }) {
    return SensorStateData(
      deviceSensorData: deviceSensorData ?? this.deviceSensorData,
      latestSensorData: latestSensorData ?? this.latestSensorData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorStateData &&
          _mapEquals(deviceSensorData, other.deviceSensorData) &&
          _mapEquals(latestSensorData, other.latestSensorData) &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode =>
      deviceSensorData.hashCode ^
      latestSensorData.hashCode ^
      isLoading.hashCode ^
      error.hashCode;

  @override
  String toString() =>
      'SensorStateData(deviceCount: ${deviceSensorData.length}, isLoading: $isLoading, error: $error)';
}

/// Helper function to compare maps
bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
