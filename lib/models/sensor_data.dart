import 'package:equatable/equatable.dart';

enum SensorType {
  temperature,
  humidity,
  pressure,
  motion,
  light,
  gas,
}

extension SensorTypeExtension on SensorType {
  String get displayName {
    switch (this) {
      case SensorType.temperature:
        return 'Temperature';
      case SensorType.humidity:
        return 'Humidity';
      case SensorType.pressure:
        return 'Pressure';
      case SensorType.motion:
        return 'Motion';
      case SensorType.light:
        return 'Light';
      case SensorType.gas:
        return 'Gas';
    }
  }

  String get unit {
    switch (this) {
      case SensorType.temperature:
        return '°C';
      case SensorType.humidity:
        return '%';
      case SensorType.pressure:
        return 'Pa';
      case SensorType.motion:
        return '';
      case SensorType.light:
        return 'lux';
      case SensorType.gas:
        return 'ppm';
    }
  }

  String get icon {
    switch (this) {
      case SensorType.temperature:
        return '🌡️';
      case SensorType.humidity:
        return '💧';
      case SensorType.pressure:
        return '⚡';
      case SensorType.motion:
        return '👤';
      case SensorType.light:
        return '💡';
      case SensorType.gas:
        return '💨';
    }
  }
}

class SensorData extends Equatable {
  final String id;
  final String deviceId;
  final SensorType type;
  final double value;
  final DateTime timestamp;
  final String unit;

  const SensorData({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.value,
    required this.timestamp,
    this.unit = '',
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'] ?? '',
      deviceId: json['deviceId'] ?? '',
      type: _sensorTypeFromString(json['type'] ?? ''),
      value: (json['value'] ?? 0).toDouble(),
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'type': type.name,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'unit': unit,
    };
  }

  SensorData copyWith({
    String? id,
    String? deviceId,
    SensorType? type,
    double? value,
    DateTime? timestamp,
    String? unit,
  }) {
    return SensorData(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      type: type ?? this.type,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      unit: unit ?? this.unit,
    );
  }

  static SensorType _sensorTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return SensorType.temperature;
      case 'humidity':
        return SensorType.humidity;
      case 'pressure':
        return SensorType.pressure;
      case 'motion':
        return SensorType.motion;
      case 'light':
        return SensorType.light;
      case 'gas':
        return SensorType.gas;
      default:
        return SensorType.temperature;
    }
  }

  @override
  List<Object?> get props => [id, deviceId, type, value, timestamp, unit];

  @override
  String toString() {
    return 'SensorData(id: $id, deviceId: $deviceId, type: $type, value: $value, timestamp: $timestamp)';
  }
}
