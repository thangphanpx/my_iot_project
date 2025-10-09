import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/device.dart';
import '../models/sensor_data.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      sendTimeout: AppConfig.apiTimeout,
    ));

    // Add interceptors for logging and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('API Request: ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode} ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  // Device API methods
  Future<List<Device>> getDevices() async {
    try {
      final response = await _dio.get('/devices');
      final List<dynamic> data = response.data;
      return data.map((json) => Device.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error fetching devices: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<Device> getDevice(String deviceId) async {
    try {
      final response = await _dio.get('/devices/$deviceId');
      return Device.fromJson(response.data);
    } on DioException catch (e) {
      print('Error fetching device: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<Device> createDevice(Device device) async {
    try {
      final response = await _dio.post('/devices', data: device.toJson());
      return Device.fromJson(response.data);
    } on DioException catch (e) {
      print('Error creating device: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<Device> updateDevice(String deviceId, Device device) async {
    try {
      final response =
          await _dio.put('/devices/$deviceId', data: device.toJson());
      return Device.fromJson(response.data);
    } on DioException catch (e) {
      print('Error updating device: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _dio.delete('/devices/$deviceId');
    } on DioException catch (e) {
      print('Error deleting device: ${e.message}');
      throw _handleError(e);
    }
  }

  // Sensor Data API methods
  Future<List<SensorData>> getSensorData({
    String? deviceId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};

      if (deviceId != null) queryParams['deviceId'] = deviceId;
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit.toString();

      final response =
          await _dio.get('/sensor-data', queryParameters: queryParams);
      final List<dynamic> data = response.data;
      return data.map((json) => SensorData.fromJson(json)).toList();
    } on DioException catch (e) {
      print('Error fetching sensor data: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<List<SensorData>> getSensorDataByDevice(String deviceId,
      {int? limit}) async {
    return getSensorData(deviceId: deviceId, limit: limit);
  }

  Future<SensorData> sendSensorData(SensorData sensorData) async {
    try {
      final response =
          await _dio.post('/sensor-data', data: sensorData.toJson());
      return SensorData.fromJson(response.data);
    } on DioException catch (e) {
      print('Error sending sensor data: ${e.message}');
      throw _handleError(e);
    }
  }

  // Dashboard summary API
  Future<Map<String, dynamic>> getDashboardSummary() async {
    try {
      final response = await _dio.get('/dashboard/summary');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('Error fetching dashboard summary: ${e.message}');
      throw _handleError(e);
    }
  }

  // Device control API
  Future<void> controlDevice(
      String deviceId, Map<String, dynamic> command) async {
    try {
      await _dio.post('/devices/$deviceId/control', data: command);
    } on DioException catch (e) {
      print('Error controlling device: ${e.message}');
      throw _handleError(e);
    }
  }

  // Settings and configuration API
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get('/settings');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('Error fetching settings: ${e.message}');
      throw _handleError(e);
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      await _dio.put('/settings', data: settings);
    } on DioException catch (e) {
      print('Error updating settings: ${e.message}');
      throw _handleError(e);
    }
  }

  // Error handling
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';
        return ApiException('$statusCode: $message');
      case DioExceptionType.cancel:
        return ApiException('Request cancelled');
      case DioExceptionType.unknown:
      default:
        return ApiException('Network error: ${error.message}');
    }
  }

  void dispose() {
    _dio.close();
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);

  @override
  String toString() => message;
}
