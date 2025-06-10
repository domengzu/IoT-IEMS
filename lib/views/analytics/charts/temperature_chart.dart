import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/dht11_reading.dart';
import 'chart_utils.dart';

class TemperatureChart extends StatelessWidget {
  final List<DHT11Reading> readings;
  final String timeRange;

  const TemperatureChart({
    super.key,
    required this.readings,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('No temperature data available'));
    }
    
    return ChartUtils.createLineChart(
      context: context,
      data: readings,
      getValue: (reading) => reading.temperature,
      getTime: (reading) => reading.timestamp,
      timeRange: timeRange,
      color: Colors.red,
      title: 'Temperature',
      yAxisLabel: 'Temperature (°C)',
    );
  }
}
