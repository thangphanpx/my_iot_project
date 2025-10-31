import 'package:flutter/material.dart';
import '../core/service_locator.dart';
import '../core/states/device_state.dart';
import '../core/states/sensor_state.dart';
import '../core/states/connection_state.dart' as conn;
import '../widgets/sensor_card.dart';
import '../widgets/chart_widget.dart';
import '../models/sensor_data.dart';

/// Reactive dashboard screen using fine-grained state management
/// Following fine-grained reactivity principles
class DashboardReactiveScreen extends StatefulWidget {
  const DashboardReactiveScreen({super.key});

  @override
  State<DashboardReactiveScreen> createState() =>
      _DashboardReactiveScreenState();
}

class _DashboardReactiveScreenState extends State<DashboardReactiveScreen> {
  late final DeviceState _deviceState;
  late final SensorState _sensorState;
  late final conn.ConnectionState _connectionState;

  @override
  void initState() {
    super.initState();

    // Get state managers from service locator
    _deviceState = serviceLocator.deviceState;
    _sensorState = serviceLocator.sensorState;
    _connectionState = serviceLocator.connectionState;

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deviceState.loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Dashboard (Reactive)'),
        actions: [
          _buildConnectionStatus(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _deviceState.loadDevices(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: StreamBuilder<DeviceStateData>(
        stream: _deviceState.stream,
        builder: (context, deviceSnapshot) {
          final deviceData = deviceSnapshot.data;

          if (deviceData == null ||
              (deviceData.isLoading && deviceData.devices.isEmpty)) {
            return _buildLoadingView();
          }

          return RefreshIndicator(
            onRefresh: () => _deviceState.loadDevices(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Overview Cards
                  _buildSystemOverview(deviceData),

                  const SizedBox(height: 16),

                  // Devices Section
                  _buildDevicesSection(deviceData),

                  const SizedBox(height: 16),

                  // Charts Section
                  _buildChartsSection(deviceData),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(),
        tooltip: 'Add Device',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return StreamBuilder<conn.ConnectionStateData>(
      stream: _connectionState.stream,
      builder: (context, connectionSnapshot) {
        final connectionData = connectionSnapshot.data;
        if (connectionData == null) return const SizedBox.shrink();

        final isConnected = connectionData.isConnected;

        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Icon(
            isConnected ? Icons.wifi : Icons.wifi_off,
            color: isConnected ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading IoT devices...'),
        ],
      ),
    );
  }

  Widget _buildSystemOverview(DeviceStateData deviceData) {
    final onlineDevices =
        deviceData.devices.where((device) => device.isOnline).toList();
    final offlineDevices =
        deviceData.devices.where((device) => !device.isOnline).toList();

    // Calculate system uptime
    final totalDevices = deviceData.devices.length;
    final systemUptime =
        totalDevices > 0 ? (onlineDevices.length / totalDevices) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Overview',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Total Devices',
                  totalDevices.toString(),
                  Icons.devices,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOverviewCard(
                  'Online',
                  onlineDevices.length.toString(),
                  Icons.wifi,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOverviewCard(
                  'Offline',
                  offlineDevices.length.toString(),
                  Icons.wifi_off,
                  Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'System Uptime',
                  '${systemUptime.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildConnectionOverviewCard(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionOverviewCard() {
    return StreamBuilder<conn.ConnectionStateData>(
      stream: _connectionState.stream,
      builder: (context, connectionSnapshot) {
        final connectionData = connectionSnapshot.data;
        final isConnected = connectionData?.isConnected ?? false;

        return _buildOverviewCard(
          'Connection',
          isConnected ? 'Online' : 'Offline',
          Icons.network_check,
          isConnected ? Colors.green : Colors.red,
        );
      },
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesSection(DeviceStateData deviceData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Devices',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showAllDevices(),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (deviceData.devices.isEmpty)
            _buildEmptyDevicesView()
          else
            ...deviceData.devices
                .take(3)
                .map((device) => SensorCard(deviceId: device.id)),
        ],
      ),
    );
  }

  Widget _buildEmptyDevicesView() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No devices found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first IoT device to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(DeviceStateData deviceData) {
    if (deviceData.devices.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sensor Charts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...deviceData.devices.take(2).expand((device) => [
                ChartWidget(
                  deviceId: device.id,
                  sensorType: SensorType.temperature,
                  title: '${device.name} - Temperature',
                ),
                const SizedBox(height: 16),
              ]),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings (Reactive)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.network_check),
              title: const Text('Connection Status'),
              subtitle: StreamBuilder<conn.ConnectionStateData>(
                stream: _connectionState.stream,
                builder: (context, snapshot) {
                  final connectionData = snapshot.data;
                  return Text(connectionData?.connectionStatus ?? 'Unknown');
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Data'),
              onTap: () {
                Navigator.pop(context);
                _deviceState.loadDevices();
              },
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Reconnect MQTT'),
              onTap: () {
                Navigator.pop(context);
                _connectionState.reconnect();
              },
            ),
            ListTile(
              leading: const Icon(Icons.error),
              title: const Text('Clear Errors'),
              onTap: () {
                Navigator.pop(context);
                _deviceState.clearError();
                _sensorState.clearError();
                _connectionState.clearError();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Device'),
        content: const Text(
            'Device configuration will be available in the next version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAllDevices() {
    // Navigate to all devices screen (will be implemented in device_detail_screen.dart)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All devices view will be available soon')),
    );
  }
}
