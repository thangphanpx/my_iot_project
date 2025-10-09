import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device.dart';
import '../models/sensor_data.dart';
import '../services/mqtt_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class IoTProvider extends ChangeNotifier {
  final MQTTService _mqttService = MQTTService();
  final ApiService _apiService = ApiService();

  // State
  List<Device> _devices = [];
  List<SensorData> _sensorData = [];
  Map<String, List<SensorData>> _deviceSensorData = {};
  bool _isLoading = false;
  String _connectionStatus = 'Disconnected';
  Timer? _dataRefreshTimer;
  Timer? _chartUpdateTimer;

  // Getters
  List<Device> get devices => _devices;
  List<SensorData> get sensorData => _sensorData;
  bool get isLoading => _isLoading;
  String get connectionStatus => _connectionStatus;

  SensorData? getLatestSensorData(String deviceId) {
    final deviceData = _deviceSensorData[deviceId];
    return deviceData?.isNotEmpty == true ? deviceData!.last : null;
  }

  List<Device> get onlineDevices =>
      _devices.where((device) => device.isOnline).toList();
  List<Device> get offlineDevices =>
      _devices.where((device) => !device.isOnline).toList();

  // Computed properties
  int get totalDevices => _devices.length;
  int get activeDevices => onlineDevices.length;
  double get systemUptime => _calculateSystemUptime();

  IoTProvider() {
    _initialize();
  }

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
        _devices = cachedDevices
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
        notifyListeners();
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
        _connectionStatus = status;
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing MQTT: $e');
      _connectionStatus = 'MQTT initialization failed';
      notifyListeners();
    }
  }

  Future<void> _loadDevicesFromAPI() async {
    _setLoading(true);
    try {
      _devices = await _apiService.getDevices();
      await _cacheDevices();
      notifyListeners();
    } catch (e) {
      print('Error loading devices from API: $e');
      _connectionStatus = 'Failed to load devices';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _cacheDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceJsons =
          _devices.map((device) => device.toJson().toString()).toList();
      await prefs.setStringList(AppConfig.devicesStorageKey, deviceJsons);
    } catch (e) {
      print('Error caching devices: $e');
    }
  }

  void _handleNewSensorData(SensorData sensorData) {
    // Add to general sensor data list
    _sensorData.add(sensorData);

    // Keep only recent data points
    if (_sensorData.length > AppConfig.maxDataPoints) {
      _sensorData.removeRange(0, _sensorData.length - AppConfig.maxDataPoints);
    }

    // Add to device-specific data
    if (_deviceSensorData[sensorData.deviceId] == null) {
      _deviceSensorData[sensorData.deviceId] = [];
    }

    _deviceSensorData[sensorData.deviceId]!.add(sensorData);

    // Keep only recent data points per device
    if (_deviceSensorData[sensorData.deviceId]!.length >
        AppConfig.maxDataPoints) {
      _deviceSensorData[sensorData.deviceId]!.removeRange(
          0,
          _deviceSensorData[sensorData.deviceId]!.length -
              AppConfig.maxDataPoints);
    }

    // Send to API
    _apiService.sendSensorData(sensorData).catchError((e) {
      print('Error sending sensor data to API: $e');
    });

    notifyListeners();
  }

  void _handleDeviceStatusUpdate(Device updatedDevice) {
    final index =
        _devices.indexWhere((device) => device.id == updatedDevice.id);
    if (index != -1) {
      _devices[index] = updatedDevice;
    } else {
      _devices.add(updatedDevice);
    }

    _cacheDevices();
    notifyListeners();
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
      notifyListeners(); // Trigger chart updates
    });
  }

  Future<void> refreshDevices() async {
    await _loadDevicesFromAPI();
  }

  Future<void> addDevice(Device device) async {
    try {
      _setLoading(true);
      final newDevice = await _apiService.createDevice(device);
      _devices.add(newDevice);
      await _cacheDevices();
      notifyListeners();
    } catch (e) {
      print('Error adding device: $e');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDevice(String deviceId, Device device) async {
    try {
      _setLoading(true);
      final updatedDevice = await _apiService.updateDevice(deviceId, device);

      final index = _devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        _devices[index] = updatedDevice;
        await _cacheDevices();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating device: $e');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      _setLoading(true);
      await _apiService.deleteDevice(deviceId);
      _devices.removeWhere((device) => device.id == deviceId);
      _deviceSensorData.remove(deviceId);
      await _cacheDevices();
      notifyListeners();
    } catch (e) {
      print('Error deleting device: $e');
      throw e;
    } finally {
      _setLoading(false);
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
      throw e;
    }
  }

  List<SensorData> getSensorDataForDevice(String deviceId, {int? limit}) {
    final deviceData = _deviceSensorData[deviceId];
    if (deviceData == null) return [];

    final data = deviceData;
    if (limit != null && data.length > limit) {
      return data.sublist(data.length - limit);
    }
    return data;
  }

  Map<String, dynamic> getDeviceStats(String deviceId) {
    final deviceData = _deviceSensorData[deviceId];
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
    if (_devices.isEmpty) return 0.0;

    final totalDevices = _devices.length;
    final onlineDevices = _devices.where((device) => device.isOnline).length;

    return (onlineDevices / totalDevices) * 100;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> reconnectMQTT() async {
    try {
      await _mqttService.initialize();
    } catch (e) {
      print('Error reconnecting MQTT: $e');
      throw e;
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
