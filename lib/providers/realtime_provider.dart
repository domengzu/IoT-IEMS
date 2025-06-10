import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/realtime_service.dart';
import '../models/dht11_reading.dart';
import '../models/noise_reading.dart';
import '../models/gas_reading.dart';

class RealtimeProvider extends ChangeNotifier {
  final RealtimeService _realtimeService;
  
  DHT11Reading? _latestDHT11;
  NoiseReading? _latestNoise;
  GasReading? _latestGas;
  
  bool _isInitialized = false;
  
  DHT11Reading? get latestDHT11 => _latestDHT11;
  NoiseReading? get latestNoise => _latestNoise;
  GasReading? get latestGas => _latestGas;
  bool get isInitialized => _isInitialized;
  
  RealtimeProvider() : _realtimeService = RealtimeService(Supabase.instance.client) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    // Set up listeners
    _realtimeService.dht11Stream.listen((reading) {
      _latestDHT11 = reading;
      notifyListeners();
    });
    
    _realtimeService.noiseStream.listen((reading) {
      _latestNoise = reading;
      notifyListeners();
    });
    
    _realtimeService.gasStream.listen((reading) {
      _latestGas = reading;
      notifyListeners();
    });
    
    // Start listening
    _realtimeService.startListening();
    _isInitialized = true;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }
}