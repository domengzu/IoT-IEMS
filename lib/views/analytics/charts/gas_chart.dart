import 'package:flutter/material.dart';
import '../../../models/gas_reading.dart';
import 'chart_utils.dart';

class GasChart extends StatelessWidget {
  final List<GasReading> readings;
  final String timeRange;

  const GasChart({
    super.key,
    required this.readings,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('No gas data available'));
    }
    
    return ChartUtils.createLineChart(
      context: context,
      data: readings,
      getValue: (reading) => reading.gasLevel,
      getTime: (reading) => reading.timestamp,
      timeRange: timeRange,
      color: Colors.teal,
      title: 'Gas Level',
      yAxisLabel: 'Gas Concentration',
    );
  }
}
