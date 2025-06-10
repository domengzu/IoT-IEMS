import 'package:flutter/foundation.dart';
import 'sensor_reading.dart';

class NoiseReading implements SensorReading {
  final String id; // We'll store this as String regardless of input type
  final double decibel;
  final DateTime timestamp;

  NoiseReading({
    required this.id,
    required this.decibel,
    required this.timestamp,
  });

  factory NoiseReading.fromJson(Map<String, dynamic> json) {
    // Handle the ID field dynamically based on its type
    String idValue;
    if (json['id'] is int) {
      idValue = json['id'].toString(); // Convert int to String
    } else if (json['id'] is String) {
      idValue = json['id'] as String; // Use as String
    } else {
      idValue = json['id']?.toString() ?? '0'; // Fallback
    }

    // Handle the decibel field safely
    double decibelValue;
    if (json['decibel'] is double) {
      decibelValue = json['decibel'] as double;
    } else if (json['decibel'] is int) {
      decibelValue = (json['decibel'] as int).toDouble();
    } else {
      decibelValue = 0.0; // Fallback
    }

    // Handle timestamp safely
    DateTime timestampValue;
    try {
      timestampValue = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now();
    } catch (e) {
      print('Error parsing timestamp: $e');
      timestampValue = DateTime.now();
    }
    
    return NoiseReading(
      id: idValue,
      decibel: decibelValue,
      timestamp: timestampValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'decibel': decibel,
      'created_at': timestamp.toIso8601String(),
    };
  }

  @override
  double getValue() => decibel;

  @override
  DateTime getTime() => timestamp;
}
