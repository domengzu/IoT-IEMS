import 'package:flutter/material.dart';
import '../../../models/dht11_reading.dart';
import 'chart_utils.dart';

class HumidityChart extends StatelessWidget {
  final List<DHT11Reading> readings;
  final String timeRange;

  const HumidityChart({
    super.key,
    required this.readings,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('No humidity data available'));
    }

    return ChartUtils.createLineChart(
      context: context,
      data: readings,
      getValue: (reading) => reading.humidity,
      getTime: (reading) => reading.timestamp,
      timeRange: timeRange,
      color: Colors.blue,
      title: 'Humidity',
      yAxisLabel: 'Humidity (%)',
    );
  }
}
