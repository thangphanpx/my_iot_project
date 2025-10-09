import 'package:equatable/equatable.dart';

enum DeviceStatus {
  online,
  offline,
  error,
  maintenance,
}

enum DeviceType {
  sensor,
  actuator,
  gateway,
  controller,
}

extension DeviceStatusExtension on DeviceStatus {
  String get displayName {
    switch (this) {
      case DeviceStatus.online:
        return 'Online';
      case DeviceStatus.offline:
        return 'Offline';
      case DeviceStatus.error:
        return 'Error';
      case DeviceStatus.maintenance:
        return 'Maintenance';
    }
  }

  String get color {
    switch (this) {
      case DeviceStatus.online:
        return 'green';
      case DeviceStatus.offline:
        return 'gray';
      case DeviceStatus.error:
        return 'red';
      case DeviceStatus.maintenance:
        return 'orange';
    }
  }
}

extension DeviceTypeExtension on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.sensor:
        return 'Sensor';
      case DeviceType.actuator:
        return 'Actuator';
      case DeviceType.gateway:
        return 'Gateway';
      case DeviceType.controller:
        return 'Controller';
    }
  }

  String get icon {
    switch (this) {
      case DeviceType.sensor:
        return '📡';
      case DeviceType.actuator:
        return '⚙️';
      case DeviceType.gateway:
        return '🌐';
      case DeviceType.controller:
        return '🎛️';
    }
  }
}

class Device extends Equatable {
  final String id;
  final String name;
  final String location;
  final DeviceType type;
  final DeviceStatus status;
  final DateTime lastSeen;
  final String ipAddress;
  final String macAddress;
  final Map<String, dynamic> metadata;
  final List<String> sensorIds;

  const Device({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.status,
    required this.lastSeen,
    required this.ipAddress,
    required this.macAddress,
    this.metadata = const {},
    this.sensorIds = const [],
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      type: _deviceTypeFromString(json['type'] ?? ''),
      status: _deviceStatusFromString(json['status'] ?? ''),
      lastSeen:
          DateTime.parse(json['lastSeen'] ?? DateTime.now().toIso8601String()),
      ipAddress: json['ipAddress'] ?? '',
      macAddress: json['macAddress'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      sensorIds: List<String>.from(json['sensorIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'type': type.name,
      'status': status.name,
      'lastSeen': lastSeen.toIso8601String(),
      'ipAddress': ipAddress,
      'macAddress': macAddress,
      'metadata': metadata,
      'sensorIds': sensorIds,
    };
  }

  Device copyWith({
    String? id,
    String? name,
    String? location,
    DeviceType? type,
    DeviceStatus? status,
    DateTime? lastSeen,
    String? ipAddress,
    String? macAddress,
    Map<String, dynamic>? metadata,
    List<String>? sensorIds,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      metadata: metadata ?? this.metadata,
      sensorIds: sensorIds ?? this.sensorIds,
    );
  }

  static DeviceType _deviceTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'sensor':
        return DeviceType.sensor;
      case 'actuator':
        return DeviceType.actuator;
      case 'gateway':
        return DeviceType.gateway;
      case 'controller':
        return DeviceType.controller;
      default:
        return DeviceType.sensor;
    }
  }

  static DeviceStatus _deviceStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return DeviceStatus.online;
      case 'offline':
        return DeviceStatus.offline;
      case 'error':
        return DeviceStatus.error;
      case 'maintenance':
        return DeviceStatus.maintenance;
      default:
        return DeviceStatus.offline;
    }
  }

  bool get isOnline => status == DeviceStatus.online;
  bool get hasError => status == DeviceStatus.error;

  @override
  List<Object?> get props => [
        id,
        name,
        location,
        type,
        status,
        lastSeen,
        ipAddress,
        macAddress,
        metadata,
        sensorIds,
      ];

  @override
  String toString() {
    return 'Device(id: $id, name: $name, type: $type, status: $status, location: $location)';
  }
}
