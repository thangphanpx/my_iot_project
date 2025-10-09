import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iot_provider.dart';
import '../widgets/sensor_card.dart';
import '../widgets/chart_widget.dart';
import '../models/sensor_data.dart';
import '../models/device.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IoTProvider>().refreshDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Dashboard'),
        actions: [
          _buildConnectionStatus(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<IoTProvider>().refreshDevices(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: Consumer<IoTProvider>(
        builder: (context, iotProvider, child) {
          if (iotProvider.isLoading && iotProvider.devices.isEmpty) {
            return _buildLoadingView();
          }

          return RefreshIndicator(
            onRefresh: () => iotProvider.refreshDevices(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // System Overview Cards
                  _buildSystemOverview(iotProvider),

                  const SizedBox(height: 16),

                  // Devices Section
                  _buildDevicesSection(iotProvider),

                  const SizedBox(height: 16),

                  // Charts Section
                  _buildChartsSection(iotProvider),

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
    return Consumer<IoTProvider>(
      builder: (context, iotProvider, child) {
        final isConnected =
            iotProvider.connectionStatus == 'Connected to MQTT broker';

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

  Widget _buildSystemOverview(IoTProvider iotProvider) {
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
                  iotProvider.totalDevices.toString(),
                  Icons.devices,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOverviewCard(
                  'Online',
                  iotProvider.activeDevices.toString(),
                  Icons.wifi,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOverviewCard(
                  'Offline',
                  (iotProvider.totalDevices - iotProvider.activeDevices)
                      .toString(),
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
                  '${iotProvider.systemUptime.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOverviewCard(
                  'Connection',
                  iotProvider.connectionStatus.contains('Connected')
                      ? 'Online'
                      : 'Offline',
                  Icons.network_check,
                  iotProvider.connectionStatus.contains('Connected')
                      ? Colors.green
                      : Colors.red,
                ),
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

  Widget _buildDevicesSection(IoTProvider iotProvider) {
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
          if (iotProvider.devices.isEmpty)
            _buildEmptyDevicesView()
          else
            ...iotProvider.devices
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

  Widget _buildChartsSection(IoTProvider iotProvider) {
    if (iotProvider.devices.isEmpty) return const SizedBox.shrink();

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
          ...iotProvider.devices.take(2).expand((device) => [
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
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.network_check),
              title: const Text('Connection Status'),
              subtitle: Consumer<IoTProvider>(
                builder: (context, provider, child) =>
                    Text(provider.connectionStatus),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Data'),
              onTap: () {
                Navigator.pop(context);
                context.read<IoTProvider>().refreshDevices();
              },
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Reconnect MQTT'),
              onTap: () {
                Navigator.pop(context);
                context.read<IoTProvider>().reconnectMQTT();
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
