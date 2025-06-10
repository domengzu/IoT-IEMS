import 'sensor_reading.dart';

class DHT11Reading implements SensorReading {
  final String id;
  final double temperature;
  final double humidity;
  final double? heatIndex;
  final DateTime timestamp;

  DHT11Reading({
    required this.id,
    required this.temperature,
    required this.humidity,
    this.heatIndex,
    required this.timestamp,
  });

  factory DHT11Reading.fromJson(Map<String, dynamic> json) {
    // Handle ID - could be int or string in database
    String idValue;
    if (json['id'] is int) {
      idValue = json['id'].toString();
    } else if (json['id'] is String) {
      idValue = json['id'];
    } else {
      idValue = json['id']?.toString() ?? '0';
    }

    // Handle temperature safely
    double temperatureValue;
    if (json['temperature'] is double) {
      temperatureValue = json['temperature'];
    } else if (json['temperature'] is int) {
      temperatureValue = (json['temperature'] as int).toDouble();
    } else {
      temperatureValue = double.tryParse(json['temperature'].toString()) ?? 0.0;
    }

    // Handle humidity safely
    double humidityValue;
    if (json['humidity'] is double) {
      humidityValue = json['humidity'];
    } else if (json['humidity'] is int) {
      humidityValue = (json['humidity'] as int).toDouble();
    } else {
      humidityValue = double.tryParse(json['humidity'].toString()) ?? 0.0;
    }

    // Handle heat index safely
    double? heatIndexValue;
    if (json['heat_index'] != null) {
      if (json['heat_index'] is double) {
        heatIndexValue = json['heat_index'];
      } else if (json['heat_index'] is int) {
        heatIndexValue = (json['heat_index'] as int).toDouble();
      } else {
        heatIndexValue = double.tryParse(json['heat_index'].toString());
      }
    }

    // Handle timestamp - checking both keys
    DateTime timestampValue;
    if (json['timestamp'] != null) {
      timestampValue = DateTime.parse(json['timestamp'].toString());
    } else if (json['created_at'] != null) {
      timestampValue = DateTime.parse(json['created_at'].toString());
    } else {
      timestampValue = DateTime.now();
    }

    return DHT11Reading(
      id: idValue,
      temperature: temperatureValue,
      humidity: humidityValue,
      heatIndex: heatIndexValue,
      timestamp: timestampValue,
    );
  }

  @override
  double getValue() {
    return temperature; // Default to temperature as the main value
  }

  @override
  DateTime getTime() {
    return timestamp;
  }
}
