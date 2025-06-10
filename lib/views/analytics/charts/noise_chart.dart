import 'package:flutter/material.dart';
import '../../../models/noise_reading.dart';
import 'chart_utils.dart';

class NoiseChart extends StatelessWidget {
  final List<NoiseReading> readings;
  final String timeRange;

  const NoiseChart({
    super.key,
    required this.readings,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('No noise data available'));
    }

    return ChartUtils.createLineChart(
      context: context,
      data: readings,
      getValue: (reading) => reading.decibel,
      getTime: (reading) => reading.timestamp,
      timeRange: timeRange,
      color: Colors.purple,
      title: 'Noise Level',
      yAxisLabel: 'Noise (dB)',
    );
  }
}
