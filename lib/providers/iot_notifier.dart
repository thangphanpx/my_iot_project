import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device.dart';
import '../models/sensor_data.dart';
import '../services/mqtt_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'iot_state.dart';

class IoTNotifier extends StateNotifier<IoTState> {
  IoTNotifier() : super(const IoTState()) {
    _initialize();
  }

  final MQTTService _mqttService = MQTTService();
  final ApiService _apiService = ApiService();

  Timer? _dataRefreshTimer;
  Timer? _chartUpdateTimer;

  Future<void> _initialize() async {
    await _loadCachedData();
    await _initializeMQTT();
    await _loadDevicesFromAPI();
    _startPeriodicUpdates();
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDevices = prefs.getStringList(AppConfig.devicesStorageKey);

      if (cachedDevices != null) {
        final devices = cachedDevices
            .map((jsonString) {
              try {
                final Map<String, dynamic> jsonData = json.decode(jsonString);
                return Device.fromJson(jsonData);
              } catch (e) {
                print('Error parsing cached device: $e');
                return null;
              }
            })
            .where((device) => device != null)
            .cast<Device>()
            .toList();

        state = state.copyWith(devices: devices);
      }
    } catch (e) {
      print('Error loading cached data: $e');
    }
  }

  Future<void> _initializeMQTT() async {
    try {
      await _mqttService.initialize();

      // Listen to MQTT streams
      _mqttService.sensorDataStream.listen((sensorData) {
        _handleNewSensorData(sensorData);
      });

      _mqttService.deviceStatusStream.listen((device) {
        _handleDeviceStatusUpdate(device);
      });

      _mqttService.connectionStatusStream.listen((status) {
        state = state.copyWith(connectionStatus: status);
      });
    } catch (e) {
      print('Error initializing MQTT: $e');
      state = state.copyWith(connectionStatus: 'MQTT initialization failed');
    }
  }

  Future<void> _loadDevicesFromAPI() async {
    state = state.copyWith(isLoading: true);
    try {
      final devices = await _apiService.getDevices();
      state = state.copyWith(devices: devices);
      await _cacheDevices();
    } catch (e) {
      print('Error loading devices from API: $e');
      state = state.copyWith(connectionStatus: 'Failed to load devices');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _cacheDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceJsons =
          state.devices.map((device) => device.toJson().toString()).toList();
      await prefs.setStringList(AppConfig.devicesStorageKey, deviceJsons);
    } catch (e) {
      print('Error caching devices: $e');
    }
  }

  void _handleNewSensorData(SensorData sensorData) {
    // Add to general sensor data list
    final updatedSensorData = [...state.sensorData, sensorData];

    // Keep only recent data points
    final recentSensorData = updatedSensorData.length > AppConfig.maxDataPoints
        ? updatedSensorData
            .sublist(updatedSensorData.length - AppConfig.maxDataPoints)
        : updatedSensorData;

    // Add to device-specific data
    final updatedDeviceSensorData =
        Map<String, List<SensorData>>.from(state.deviceSensorData);

    if (updatedDeviceSensorData[sensorData.deviceId] == null) {
      updatedDeviceSensorData[sensorData.deviceId] = [];
    }

    final deviceData = [
      ...updatedDeviceSensorData[sensorData.deviceId]!,
      sensorData
    ];

    // Keep only recent data points per device
    final recentDeviceData = deviceData.length > AppConfig.maxDataPoints
        ? deviceData.sublist(deviceData.length - AppConfig.maxDataPoints)
        : deviceData;

    updatedDeviceSensorData[sensorData.deviceId] = recentDeviceData;

    // Update state
    state = state.copyWith(
      sensorData: recentSensorData,
      deviceSensorData: updatedDeviceSensorData,
    );

    // Send to API
    _apiService.sendSensorData(sensorData).catchError((e) {
      print('Error sending sensor data to API: $e');
    });
  }

  void _handleDeviceStatusUpdate(Device updatedDevice) {
    final devices = [...state.devices];
    final index = devices.indexWhere((device) => device.id == updatedDevice.id);

    if (index != -1) {
      devices[index] = updatedDevice;
    } else {
      devices.add(updatedDevice);
    }

    state = state.copyWith(devices: devices);
    _cacheDevices();
  }

  void _startPeriodicUpdates() {
    // Refresh device data every 30 seconds
    _dataRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_mqttService.isConnected) {
        _loadDevicesFromAPI();
      }
    });

    // Update charts every minute
    _chartUpdateTimer = Timer.periodic(AppConfig.chartUpdateInterval, (timer) {
      // Trigger chart updates by copying state (no changes needed)
      state = state.copyWith();
    });
  }

  Future<void> refreshDevices() async {
    await _loadDevicesFromAPI();
  }

  Future<void> addDevice(Device device) async {
    state = state.copyWith(isLoading: true);
    try {
      final newDevice = await _apiService.createDevice(device);
      final devices = [...state.devices, newDevice];
      state = state.copyWith(devices: devices);
      await _cacheDevices();
    } catch (e) {
      print('Error adding device: $e');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateDevice(String deviceId, Device device) async {
    state = state.copyWith(isLoading: true);
    try {
      final updatedDevice = await _apiService.updateDevice(deviceId, device);

      final devices = [...state.devices];
      final index = devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        devices[index] = updatedDevice;
        state = state.copyWith(devices: devices);
        await _cacheDevices();
      }
    } catch (e) {
      print('Error updating device: $e');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteDevice(deviceId);
      final devices =
          state.devices.where((device) => device.id != deviceId).toList();
      final deviceSensorData =
          Map<String, List<SensorData>>.from(state.deviceSensorData);
      deviceSensorData.remove(deviceId);

      state = state.copyWith(
        devices: devices,
        deviceSensorData: deviceSensorData,
      );
      await _cacheDevices();
    } catch (e) {
      print('Error deleting device: $e');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> controlDevice(
      String deviceId, Map<String, dynamic> command) async {
    try {
      await _apiService.controlDevice(deviceId, command);
      // Optionally refresh device status after control command
      await refreshDevices();
    } catch (e) {
      print('Error controlling device: $e');
      rethrow;
    }
  }

  Future<void> reconnectMQTT() async {
    try {
      await _mqttService.initialize();
    } catch (e) {
      print('Error reconnecting MQTT: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _mqttService.dispose();
    _dataRefreshTimer?.cancel();
    _chartUpdateTimer?.cancel();
    super.dispose();
  }
}
