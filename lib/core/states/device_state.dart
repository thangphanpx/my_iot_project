import 'dart:async';
import '../../models/device.dart';
import '../base/reactive_state.dart';
import '../interfaces/device_repository_interface.dart';

/// Device state management with fine-grained reactivity
/// Following Single Responsibility Principle (SRP)
class DeviceState extends ReactiveState<DeviceStateData> {
  final DeviceRepositoryInterface _deviceRepository;
  StreamSubscription<List<Device>>? _devicesSubscription;

  DeviceState(
    this._deviceRepository, {
    DeviceStateData? initialState,
  }) : super(
          initialState ??
              const DeviceStateData(
                devices: [],
                isLoading: false,
                error: null,
              ),
        ) {
    _initialize();
  }

  void _initialize() {
    // Watch for device changes
    _devicesSubscription = _deviceRepository.watchDevices().listen(
      (devices) {
        update((current) => current.copyWith(
              devices: devices,
              isLoading: false,
              error: null,
            ));
      },
      onError: (error) {
        update((current) => current.copyWith(
              error: error.toString(),
              isLoading: false,
            ));
      },
    );
  }

  /// Load devices from repository
  Future<void> loadDevices() async {
    update((current) => current.copyWith(isLoading: true, error: null));

    try {
      final devices = await _deviceRepository.getDevices();
      update((current) => current.copyWith(
            devices: devices,
            isLoading: false,
            error: null,
          ));
    } catch (error) {
      update((current) => current.copyWith(
            error: error.toString(),
            isLoading: false,
          ));
    }
  }

  /// Add a new device
  Future<void> addDevice(Device device) async {
    try {
      await _deviceRepository.createDevice(device);
      // No need to manually update state - repository stream will notify
    } catch (error) {
      update((current) => current.copyWith(error: error.toString()));
      rethrow;
    }
  }

  /// Update an existing device
  Future<void> updateDevice(String deviceId, Device device) async {
    try {
      await _deviceRepository.updateDevice(deviceId, device);
      // No need to manually update state - repository stream will notify
    } catch (error) {
      update((current) => current.copyWith(error: error.toString()));
      rethrow;
    }
  }

  /// Delete a device
  Future<void> deleteDevice(String deviceId) async {
    try {
      await _deviceRepository.deleteDevice(deviceId);
      // No need to manually update state - repository stream will notify
    } catch (error) {
      update((current) => current.copyWith(error: error.toString()));
      rethrow;
    }
  }

  /// Clear error state
  void clearError() {
    update((current) => current.copyWith(error: null));
  }

  /// Get devices by status
  List<Device> get onlineDevices =>
      state.devices.where((device) => device.isOnline).toList();
  List<Device> get offlineDevices =>
      state.devices.where((device) => !device.isOnline).toList();

  /// Get device by ID
  Device? getDeviceById(String deviceId) {
    try {
      return state.devices.firstWhere((device) => device.id == deviceId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    super.dispose();
  }
}

/// Immutable state data class for devices
/// Following Immutability principle
class DeviceStateData {
  final List<Device> devices;
  final bool isLoading;
  final String? error;

  const DeviceStateData({
    required this.devices,
    required this.isLoading,
    this.error,
  });

  DeviceStateData copyWith({
    List<Device>? devices,
    bool? isLoading,
    String? error,
  }) {
    return DeviceStateData(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceStateData &&
          devices == other.devices &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => devices.hashCode ^ isLoading.hashCode ^ error.hashCode;

  @override
  String toString() =>
      'DeviceStateData(devices: ${devices.length}, isLoading: $isLoading, error: $error)';
}
