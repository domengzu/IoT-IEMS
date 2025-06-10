import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/dht11_reading.dart';
import '../models/noise_reading.dart';
import '../models/gas_reading.dart';

class RealtimeService {
  final SupabaseClient _client;
  RealtimeChannel? _dht11Channel;
  RealtimeChannel? _noiseChannel;
  RealtimeChannel? _gasChannel;
  
  // Stream controllers to broadcast changes to the UI
  final _dht11Controller = StreamController<DHT11Reading>.broadcast();
  final _noiseController = StreamController<NoiseReading>.broadcast();
  final _gasController = StreamController<GasReading>.broadcast();
  
  // Expose streams for consumers
  Stream<DHT11Reading> get dht11Stream => _dht11Controller.stream;
  Stream<NoiseReading> get noiseStream => _noiseController.stream;
  Stream<GasReading> get gasStream => _gasController.stream;

  RealtimeService(this._client);
  
  void startListening() {
    // Subscribe to DHT11 readings
    _dht11Channel = _client
      .channel('public:dht11_readings')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'dht11_readings',
        callback: (payload) {
          final newReading = DHT11Reading.fromJson(payload.newRecord);
          _dht11Controller.add(newReading);
        },
      )
      .subscribe();
      
    // Subscribe to noise readings
    _noiseChannel = _client
      .channel('public:noise_readings')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'noise_readings',
        callback: (payload) {
          final newReading = NoiseReading.fromJson(payload.newRecord);
          _noiseController.add(newReading);
        },
      )
      .subscribe();
      
    // Subscribe to gas readings
    _gasChannel = _client
      .channel('public:gas_readings')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'gas_readings',
        callback: (payload) {
          final newReading = GasReading.fromJson(payload.newRecord);
          _gasController.add(newReading);
        },
      )
      .subscribe();
  }

  void dispose() {
    // Clean up subscriptions
    _dht11Channel?.unsubscribe();
    _noiseChannel?.unsubscribe();
    _gasChannel?.unsubscribe();
    _dht11Controller.close();
    _noiseController.close();
    _gasController.close();
  }
}