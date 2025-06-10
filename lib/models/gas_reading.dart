import 'sensor_reading.dart';

class GasReading implements SensorReading {
  final String id;
  @override
  final DateTime timestamp;
  final double gasLevel;

  GasReading({
    required this.id,
    required this.timestamp,
    required this.gasLevel,
  });

  factory GasReading.fromJson(Map<String, dynamic> json) {
    return GasReading(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      gasLevel: double.parse(json['gas_level'].toString()),
    );
  }
}
