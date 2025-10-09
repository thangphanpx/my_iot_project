import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iot_provider.dart';
import '../widgets/chart_widget.dart';
import '../models/device.dart';
import '../models/sensor_data.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IoTProvider>().refreshDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDeviceDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDeviceDialog(),
          ),
        ],
      ),
      body: Consumer<IoTProvider>(
        builder: (context, iotProvider, child) {
          final device = iotProvider.devices.firstWhere(
            (d) => d.id == widget.deviceId,
            orElse: () => Device(
              id: widget.deviceId,
              name: 'Unknown Device',
              location: 'Unknown Location',
              type: DeviceType.sensor,
              status: DeviceStatus.offline,
              lastSeen: DateTime.now(),
              ipAddress: '0.0.0.0',
              macAddress: '00:00:00:00:00:00',
            ),
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Device Header Card
                _buildDeviceHeader(device),

                // Device Information
                _buildDeviceInfo(device),

                // Control Panel
                _buildControlPanel(device),

                // Charts Section
                _buildChartsSection(device),

                // Recent Activity
                _buildRecentActivity(device),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceHeader(Device device) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  device.type.icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.location,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(device.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor(device.status),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getStatusColor(device.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      device.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(device.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  'Last Seen',
                  _formatLastSeen(device.lastSeen),
                  Icons.access_time,
                ),
              ),
              Expanded(
                child: _buildHeaderStat(
                  'IP Address',
                  device.ipAddress,
                  Icons.network_wifi,
                ),
              ),
              Expanded(
                child: _buildHeaderStat(
                  'MAC Address',
                  device.macAddress,
                  Icons.memory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfo(Device device) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Device ID', device.id),
          _buildInfoRow('Type', device.type.displayName),
          _buildInfoRow('Status', device.status.displayName),
          _buildInfoRow('Location', device.location),
          if (device.metadata.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Additional Info',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...device.metadata.entries.map(
                (entry) => _buildInfoRow(entry.key, entry.value.toString())),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(Device device) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Control',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      device.isOnline ? () => _controlDevice('restart') : null,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Restart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: device.isOnline
                      ? () => _controlDevice('calibrate')
                      : null,
                  icon: const Icon(Icons.tune),
                  label: const Text('Calibrate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: device.hasError
                      ? () => _controlDevice('reset_error')
                      : null,
                  icon: const Icon(Icons.error_outline),
                  label: const Text('Reset Error'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(Device device) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor Charts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ChartWidget(
            deviceId: device.id,
            sensorType: SensorType.temperature,
            title: 'Temperature Trend',
          ),
          const SizedBox(height: 16),
          ChartWidget(
            deviceId: device.id,
            sensorType: SensorType.humidity,
            title: 'Humidity Trend',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(Device device) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Consumer<IoTProvider>(
            builder: (context, iotProvider, child) {
              final sensorData = iotProvider.getSensorDataForDevice(
                device.id,
                limit: 10,
              );

              if (sensorData.isEmpty) {
                return const Center(
                  child: Text('No recent activity'),
                );
              }

              return Column(
                children:
                    sensorData.map((data) => _buildActivityItem(data)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(SensorData sensorData) {
    return ListTile(
      leading: Text(
        sensorData.type.icon,
        style: const TextStyle(fontSize: 20),
      ),
      title: Text(sensorData.type.displayName),
      subtitle: Text(_formatTimestamp(sensorData.timestamp)),
      trailing: Text(
        '${sensorData.value.toStringAsFixed(1)}${sensorData.type.unit}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
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

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

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

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _controlDevice(String action) {
    final iotProvider = context.read<IoTProvider>();
    iotProvider.controlDevice(widget.deviceId, {'action': action});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent $action command to device')),
    );
  }

  void _showEditDeviceDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Edit device functionality will be available soon')),
    );
  }

  void _showDeleteDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: const Text(
            'Are you sure you want to delete this device? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<IoTProvider>().deleteDevice(widget.deviceId);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Device deleted successfully')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
