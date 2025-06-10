import 'package:flutter/foundation.dart';
import 'dart:async';

class RefreshService extends ChangeNotifier {
  Timer? _refreshTimer;
  final Duration _refreshInterval;

  // Specific data refresh controllers
  final _dht11RefreshController = StreamController<void>.broadcast();
  final _noiseRefreshController = StreamController<void>.broadcast();
  final _gasRefreshController = StreamController<void>.broadcast();
  final _globalRefreshController = StreamController<void>.broadcast();

  // Expose specific data streams
  Stream<void> get dht11RefreshStream => _dht11RefreshController.stream;
  Stream<void> get noiseRefreshStream => _noiseRefreshController.stream;
  Stream<void> get gasRefreshStream => _gasRefreshController.stream;
  Stream<void> get refreshStream => _globalRefreshController.stream;

  // In-memory flag for refresh state
  bool _refreshInProgress = false;
  bool get refreshInProgress => _refreshInProgress;

  // Timestamp of last refresh
  DateTime _lastRefresh = DateTime.now();
  DateTime get lastRefresh => _lastRefresh;

  // Allow customization of refresh interval
  RefreshService({Duration refreshInterval = const Duration(seconds: 1)})
    : _refreshInterval = refreshInterval {
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      refreshDataOnly();
    });
  }

  // Refresh data only without triggering full UI rebuilds
  void refreshDataOnly() {
    // Add events to specific refresh streams
    _dht11RefreshController.add(null); // Make sure this is present
    _noiseRefreshController.add(null);
    _gasRefreshController.add(null);

    // Update timestamp
    _lastRefresh = DateTime.now();
  }

  // Full refresh with UI update (for manual refresh button)
  void triggerFullRefresh() {
    _refreshInProgress = true;
    notifyListeners();

    // Add event to the global stream
    _globalRefreshController.add(null);

    // Refresh all data
    refreshDataOnly();

    // Reset flag after short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _refreshInProgress = false;
      notifyListeners();
    });
  }

  void setRefreshInterval(Duration interval) {
    if (interval.inMilliseconds != _refreshInterval.inMilliseconds) {
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(interval, (_) {
        refreshDataOnly();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _dht11RefreshController.close();
    _noiseRefreshController.close();
    _gasRefreshController.close();
    _globalRefreshController.close();
    super.dispose();
  }
}
