import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_reading.dart';

abstract class SensorService<T extends SensorReading> {
  final SupabaseClient client;

  SensorService(this.client);

  Future<List<T>> getLatestReadings({int limit = 20});
}
