import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gas_reading.dart';
import 'dart:async';

class GasService {
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  final _latestReadingController = StreamController<GasReading>.broadcast();

  // Expose stream of latest readings
  Stream<GasReading> get latestReadingStream => _latestReadingController.stream;

  GasService(this._client);

  // Get latest readings (one-time fetch)
  Future<List<GasReading>> getLatestReadings({int limit = 10}) async {
    final response = await _client
        .from('gas_readings')
        .select()
        .order('timestamp', ascending: false)
        .limit(limit);
    
    return (response as List)
        .map((data) => GasReading.fromJson(data))
        .toList();
  }

  // Get latest reading
  Future<GasReading?> getLatestReading() async {
    final response = await _client
        .from('gas_readings')
        .select()
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();
    
    return response != null ? GasReading.fromJson(response) : null;
  }

  // Subscribe to real-time updates
  void subscribeToLatestReading() {
    _channel = _client
      .channel('public:gas_readings')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'gas_readings',
        callback: (payload) {
          final newReading = GasReading.fromJson(payload.newRecord);
          _latestReadingController.add(newReading);
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

  // Add this method to the GasService class
  Future<void> refreshData() async {
    try {
      final readings = await getLatestReadings();
      if (readings.isNotEmpty) {
        // If we got new data, add it to the stream
        _latestReadingController.add(readings.first);
      }
    } catch (e) {
      print('Error refreshing Gas data: $e');
    }
  }
}
