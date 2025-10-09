import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../models/device.dart';
import '../providers/iot_provider.dart';
import '../config/app_config.dart';

class SensorCard extends StatelessWidget {
  final String deviceId;
  final SensorType? sensorType;
  final VoidCallback? onTap;

  const SensorCard({
    super.key,
    required this.deviceId,
    this.sensorType,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<IoTProvider>(
      builder: (context, iotProvider, child) {
        final device = iotProvider.devices.firstWhere(
          (d) => d.id == deviceId,
          orElse: () => Device(
            id: deviceId,
            name: 'Unknown Device',
            location: 'Unknown Location',
            type: DeviceType.sensor,
            status: DeviceStatus.offline,
            lastSeen: DateTime.now(),
            ipAddress: '0.0.0.0',
            macAddress: '00:00:00:00:00:00',
          ),
        );

        SensorData? latestData;
        if (sensorType != null) {
          latestData = iotProvider.sensorData
              .where((data) =>
                  data.deviceId == deviceId && data.type == sensorType)
              .lastOrNull;
        } else {
          latestData = iotProvider.getLatestSensorData(deviceId);
        }

        return Card(
          elevation: AppConfig.cardElevation,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      // Device Icon and Info
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(device.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          device.type.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              device.location,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Status Indicator
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(device.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sensor Data Section
                  if (latestData != null) ...[
                    Row(
                      children: [
                        Text(
                          sensorType?.icon ?? '📊',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sensorType?.displayName ?? 'Sensor Data',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatValue(latestData),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Timestamp
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(latestData.timestamp),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // No Data State
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sensors_off,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No sensor data available',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[500],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.online:
        return Colors.green;
      case DeviceStatus.offline:
        return Colors.grey;
      case DeviceStatus.error:
        return Colors.red;
      case DeviceStatus.maintenance:
        return Colors.orange;
    }
  }

  String _formatValue(SensorData data) {
    return '${data.value.toStringAsFixed(1)}${data.type.unit}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
