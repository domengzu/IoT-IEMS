import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dht11_reading.dart';
import 'dart:async';

class DHT11Service {
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  final _latestReadingController = StreamController<DHT11Reading>.broadcast();

  // Expose stream of latest readings
  Stream<DHT11Reading> get latestReadingStream =>
      _latestReadingController.stream;

  DHT11Service(this._client);

  // Get latest readings (one-time fetch)
  Future<List<DHT11Reading>> getLatestReadings({int limit = 10}) async {
    try {
      print('Fetching DHT11 readings...');
      final response = await _client
          .from('dht11_readings')
          .select('*') // Select all columns
          .order('timestamp', ascending: false) // Changed to timestamp
          .limit(limit);

      print('DHT11 response: $response');

      return (response as List)
          .map((data) => DHT11Reading.fromJson(data))
          .toList();
    } catch (e) {
      print('Error fetching DHT11 readings: $e');
      return [];
    }
  }

  // Get latest reading with minimal overhead
  Future<DHT11Reading?> getLatestReadingFast() async {
    try {
      print('Fetching latest DHT11 reading...');
      final response = await _client
          .from('dht11_readings')
          .select(
            'id, timestamp, temperature, humidity, heat_index',
          ) // Match table columns
          .order('timestamp', ascending: false) // Changed to timestamp
          .limit(1)
          .single();

      print('Latest DHT11 reading: $response');

      return DHT11Reading.fromJson(response);
    } catch (e) {
      print('Error fetching latest DHT11 reading: $e');
      return null;
    }
  }

  // Subscribe to real-time updates
  void subscribeToLatestReading() {
    print('Setting up DHT11 realtime subscription...');
    _channel = _client
        .channel('public:dht11_readings')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'dht11_readings',
          callback: (payload) {
            try {
              print('Received DHT11 update: ${payload.newRecord}');
              final newReading = DHT11Reading.fromJson(payload.newRecord);
              _latestReadingController.add(newReading);
            } catch (e) {
              print('Error processing DHT11 realtime data: $e');
            }
          },
        )
        .subscribe((status, [error]) {
          print('DHT11 channel status: $status');
          // Immediately fetch latest data when connected to ensure we have current data
          if (status == 'SUBSCRIBED') {
            refreshData();
          }
          if (error != null) {
            print('DHT11 subscription error: $error');
          }
        });
  }

  // Refresh data programmatically
  Future<void> refreshData() async {
    try {
      final reading = await getLatestReadingFast();
      if (reading != null) {
        print(
          'Adding new DHT11 reading to stream: ${reading.temperature}°C, ${reading.humidity}%',
        );
        _latestReadingController.add(reading);
      }
    } catch (e) {
      print('Error refreshing DHT11 data: $e');
    }
  }

  void cancelSubscription() {
    _channel?.unsubscribe();
  }

  void dispose() {
    cancelSubscription();
    _latestReadingController.close();
  }
}
