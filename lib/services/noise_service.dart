import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/noise_reading.dart';
import 'dart:async';

class NoiseService {
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  final _latestReadingController = StreamController<NoiseReading>.broadcast();

  // Expose stream of latest readings
  Stream<NoiseReading> get latestReadingStream => _latestReadingController.stream;

  NoiseService(this._client);

  // Get latest readings (one-time fetch)
  Future<List<NoiseReading>> getLatestReadings({int limit = 10}) async {
    try {
      final response = await _client
          .from('noise_data')
          .select()
          .order('created_at', ascending: false)  // Use created_at field
          .limit(limit);
      
      return (response as List)
          .map((data) => NoiseReading.fromJson(data))
          .toList();
    } catch (e) {
      print('Error fetching noise readings: $e');
      rethrow;
    }
  }

  // Get latest reading
  Future<NoiseReading?> getLatestReading() async {
    try {
      final response = await _client
          .from('noise_data')
          .select()
          .order('created_at', ascending: false)  // Use created_at field
          .limit(1)
          .maybeSingle();
      
      return response != null ? NoiseReading.fromJson(response) : null;
    } catch (e) {
      print('Error fetching latest noise reading: $e');
      rethrow;
    }
  }

  // Subscribe to real-time updates
  void subscribeToLatestReading() {
    _channel = _client
      .channel('public:noise_data')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'noise_data',
        callback: (payload) {
          try {
            final newReading = NoiseReading.fromJson(payload.newRecord as Map<String, dynamic>);
            _latestReadingController.add(newReading);
          } catch (e) {
            print('Error processing realtime noise data: $e');
          }
        },
      )
      .subscribe();
  }

  // Cancel subscription
  void cancelSubscription() {
    _channel?.unsubscribe();
  }

  // Clean up resources
  void dispose() {
    cancelSubscription();
    _latestReadingController.close();
  }

  // Add this method to the NoiseService class
  Future<void> refreshData() async {
    try {
      final readings = await getLatestReadings();
      if (readings.isNotEmpty) {
        // If we got new data, add it to the stream
        _latestReadingController.add(readings.first);
      }
    } catch (e) {
      print('Error refreshing Noise data: $e');
    }
  }
}
