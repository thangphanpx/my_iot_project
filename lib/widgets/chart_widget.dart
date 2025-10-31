import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_data.dart';
import '../providers/iot_providers.dart';
import '../config/app_config.dart';

class ChartWidget extends ConsumerStatefulWidget {
  final String deviceId;
  final SensorType sensorType;
  final String title;
  final double height;

  const ChartWidget({
    super.key,
    required this.deviceId,
    required this.sensorType,
    this.title = 'Sensor Data',
    this.height = 200,
  });

  @override
  ConsumerState<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends ConsumerState<ChartWidget> {
  List<FlSpot> _chartData = [];
  double _minY = 0;
  double _maxY = 100;

  @override
  Widget build(BuildContext context) {
    final sensorDataForDevice =
        ref.watch(deviceSensorDataForDeviceProvider(widget.deviceId));
    final sensorData = sensorDataForDevice
        .where((data) => data.type == widget.sensorType)
        .toList();

    _updateChartData(sensorData);

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Text(
                widget.sensorType.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${sensorData.length} points',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chart
          Expanded(
            child: sensorData.isEmpty
                ? _buildEmptyState()
                : LineChart(
                    _buildChartData(sensorData),
                    duration: const Duration(milliseconds: 250),
                  ),
          ),

          // Statistics Row
          if (sensorData.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildStatisticsRow(sensorData),
          ],
        ],
      ),
    );
  }

  void _updateChartData(List<SensorData> data) {
    if (data.isEmpty) {
      _chartData = [];
      return;
    }

    _chartData = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final dataPoint = entry.value;
      return FlSpot(index, dataPoint.value);
    }).toList();

    // Calculate Y-axis bounds
    final values = data.map((d) => d.value).toList();
    _minY = values.reduce((a, b) => a < b ? a : b);
    _maxY = values.reduce((a, b) => a > b ? a : b);

    // Add some padding to Y-axis
    final padding = (_maxY - _minY) * 0.1;
    _minY = _minY - padding;
    _maxY = _maxY + padding;

    // Ensure minimum range
    if (_maxY - _minY < 1) {
      _minY = _minY - 0.5;
      _maxY = _maxY + 0.5;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(List<SensorData> data) {
    final latest = data.last;
    final average =
        data.map((d) => d.value).reduce((a, b) => a + b) / data.length;
    final min = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final max = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        _buildStatChip('Current',
            '${latest.value.toStringAsFixed(1)}${widget.sensorType.unit}'),
        const SizedBox(width: 8),
        _buildStatChip(
            'Avg', '${average.toStringAsFixed(1)}${widget.sensorType.unit}'),
        const SizedBox(width: 8),
        _buildStatChip(
            'Min', '${min.toStringAsFixed(1)}${widget.sensorType.unit}'),
        const SizedBox(width: 8),
        _buildStatChip(
            'Max', '${max.toStringAsFixed(1)}${widget.sensorType.unit}'),
      ],
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<SensorData> data) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: (_maxY - _minY) / 5,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey[300],
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey[300],
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (data.length / 5).roundToDouble(),
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= data.length) return const Text('');
              final index = value.toInt();
              if (index % ((data.length / 4).round()) != 0)
                return const Text('');
              final timestamp = data[index].timestamp;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _formatTime(timestamp),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (_maxY - _minY) / 4,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[300]!),
      ),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: _minY,
      maxY: _maxY,
      lineBarsData: [
        LineChartBarData(
          spots: _chartData,
          isCurved: true,
          curveSmoothness: 0.3,
          color: Theme.of(context).primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
