import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/gas_reading.dart';
import '../../common/reading_gauge.dart';
import '../../common/reading_row.dart';

class GasDataView extends StatelessWidget {
  final List<GasReading> readings;
  final Future<void> Function() onRefresh;

  const GasDataView({
    super.key,
    required this.readings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Current gas reading card
        GasCurrentCard(reading: readings.first),
        // Historical gas readings
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.builder(
              itemCount: readings.length,
              itemBuilder: (context, index) {
                return GasListItem(reading: readings[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class GasCurrentCard extends StatelessWidget {
  final GasReading reading;

  const GasCurrentCard({super.key, required this.reading});

  // Helper methods for gas level interpretation
  String _getGasCategory(double level) {
    if (level < 100) return 'Low';
    if (level < 300) return 'Moderate';
    if (level < 500) return 'High';
    return 'Dangerous';
  }

  Color _getGasColor(double level) {
    if (level < 100) return Colors.green;
    if (level < 300) return const Color.fromARGB(255, 204, 186, 23);
    if (level < 500) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final gasCategory = _getGasCategory(reading.gasLevel);
    final gasColor = _getGasColor(reading.gasLevel);

    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Gas Level',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Updated: ${DateFormat('HH:mm:ss').format(reading.timestamp)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ReadingGauge(
                  label: gasCategory,
                  value: reading.gasLevel.toStringAsFixed(1),
                  icon: Icons.air,
                  color: gasColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GasListItem extends StatelessWidget {
  final GasReading reading;

  const GasListItem({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat(
      'MMM dd, yyyy HH:mm:ss',
    ).format(reading.timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading at $formattedTime',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ReadingRow(
              label: 'Gas Level',
              value: reading.gasLevel.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }
}
