import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../models/dht11_reading.dart';
import '../../models/noise_reading.dart';
import '../../models/gas_reading.dart';
import '../../services/dht11_service.dart';
import '../../services/noise_service.dart';
import '../../services/gas_service.dart';
import '../../services/refresh_service.dart';
import '../common/empty_view.dart';
import '../common/loading_view.dart';
import 'tab_views/dht11_view.dart';
import 'tab_views/noise_view.dart';
import 'tab_views/gas_view.dart';
import 'tab_views/overview_view.dart';

class MonitoringDashboard extends StatefulWidget {
  const MonitoringDashboard({super.key});

  @override
  State<MonitoringDashboard> createState() => _MonitoringDashboardState();
}

class _MonitoringDashboardState extends State<MonitoringDashboard> {
  late final DHT11Service _dht11Service;
  late final NoiseService _noiseService;
  late final GasService _gasService;

  List<DHT11Reading> _dht11Readings = [];
  List<NoiseReading> _noiseReadings = [];
  List<GasReading> _gasReadings = [];

  bool _loadingDHT11 = true;
  bool _loadingNoise = true;
  bool _loadingGas = true;
  DateTime _lastUpdated = DateTime.now();

  // Subscriptions for real-time updates
  List<StreamSubscription<dynamic>> _subscriptions = [];

  // Add timer for batched updates
  Timer? _updateUITimer;
  List<DHT11Reading> _pendingDHT11Updates = [];
  List<NoiseReading> _pendingNoiseUpdates = [];
  List<GasReading> _pendingGasUpdates = [];
  bool _hasNewData = false;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _dht11Service = DHT11Service(client);
    _noiseService = NoiseService(client);
    _gasService = GasService(client);

    _fetchAllData();
    _setupRealtimeListeners();
    _setupDataRefreshListeners();

    // Set up batched UI updates
    _updateUITimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_hasNewData) {
        setState(() {
          // Apply all pending updates at once
          if (_pendingDHT11Updates.isNotEmpty) {
            _dht11Readings.insertAll(0, _pendingDHT11Updates);
            if (_dht11Readings.length > 20) {
              _dht11Readings = _dht11Readings.sublist(0, 20);
            }
          }

          // Apply noise updates
          if (_pendingNoiseUpdates.isNotEmpty) {
            _noiseReadings.insertAll(0, _pendingNoiseUpdates);
            if (_noiseReadings.length > 20) {
              _noiseReadings = _noiseReadings.sublist(0, 20);
            }
          }

          // Apply gas updates
          if (_pendingGasUpdates.isNotEmpty) {
            _gasReadings.insertAll(0, _pendingGasUpdates);
            if (_gasReadings.length > 20) {
              _gasReadings = _gasReadings.sublist(0, 20);
            }
          }

          _lastUpdated = DateTime.now();
          _pendingDHT11Updates = [];
          _pendingNoiseUpdates = [];
          _pendingGasUpdates = [];
          _hasNewData = false;
        });
      }
    });
  }

  void _setupDataRefreshListeners() {
    final refreshService = Provider.of<RefreshService>(context, listen: false);

    // Listen for individual data refreshes
    _subscriptions.add(
      refreshService.dht11RefreshStream.listen((_) {
        _dht11Service.refreshData(); // Make sure this is called regularly
      }),
    );

    _subscriptions.add(
      refreshService.noiseRefreshStream.listen((_) {
        _noiseService.refreshData();
      }),
    );

    _subscriptions.add(
      refreshService.gasRefreshStream.listen((_) {
        _gasService.refreshData();
      }),
    );

    // Listen for real-time data updates
    _subscriptions.add(
      _dht11Service.latestReadingStream.listen((reading) {
        if (mounted) {
          setState(() {
            if (_dht11Readings.isEmpty ||
                reading.id != _dht11Readings.first.id) {
              _dht11Readings.insert(0, reading);
              if (_dht11Readings.length > 20) {
                _dht11Readings = _dht11Readings.sublist(0, 20);
              }
              _lastUpdated = DateTime.now();
              print(
                'DHT11 data updated: ${reading.temperature}°C, ${reading.humidity}%',
              );
            }
          });
        }
      }),
    );

    // Similar listeners for noise and gas
    _subscriptions.add(
      _noiseService.latestReadingStream.listen((reading) {
        if (mounted) {
          setState(() {
            _noiseReadings.insert(0, reading);
            if (_noiseReadings.length > 20) {
              _noiseReadings = _noiseReadings.sublist(0, 20);
            }
            _lastUpdated = DateTime.now();

            // _showNewDataNotification('Noise');
          });
        }
      }),
    );

    _subscriptions.add(
      _gasService.latestReadingStream.listen((reading) {
        if (mounted) {
          setState(() {
            _gasReadings.insert(0, reading);
            if (_gasReadings.length > 20) {
              _gasReadings = _gasReadings.sublist(0, 20);
            }
            _lastUpdated = DateTime.now();

            // _showNewDataNotification('Gas');
          });
        }
      }),
    );
  }

  /// Show a subtle notification when new data arrives
  // void _showNewDataNotification(String sensorType) {
  //   // Optional: Show a non-intrusive indicator that new data arrived
  //   if (mounted) {
  //     ScaffoldMessenger.of(context).clearSnackBars();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('New $sensorType reading received'),
  //         duration: const Duration(seconds: 1),
  //         behavior: SnackBarBehavior.floating,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //         margin: const EdgeInsets.all(10),
  //         action: SnackBarAction(
  //           label: 'Dismiss',
  //           onPressed: () {
  //             ScaffoldMessenger.of(context).hideCurrentSnackBar();
  //           },
  //         ),
  //       ),
  //     );
  //   }
  // }

  Future<void> _fetchAllData() async {
    await Future.wait([_fetchDHT11Data(), _fetchNoiseData(), _fetchGasData()]);

    setState(() {
      _lastUpdated = DateTime.now();
    });
  }

  Future<void> _fetchDHT11Data() async {
    setState(() {
      _loadingDHT11 = true;
    });

    try {
      final readings = await _dht11Service.getLatestReadings();
      setState(() {
        _dht11Readings = readings;
        _loadingDHT11 = false;
      });
    } catch (error) {
      setState(() {
        _loadingDHT11 = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading DHT11 data: $error')),
        );
      }
    }
  }

  Future<void> _fetchNoiseData() async {
    setState(() {
      _loadingNoise = true;
    });

    try {
      final readings = await _noiseService.getLatestReadings();
      setState(() {
        _noiseReadings = readings;
        _loadingNoise = false;
      });
    } catch (error) {
      setState(() {
        _loadingNoise = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading noise data: $error')),
        );
      }
    }
  }

  Future<void> _fetchGasData() async {
    setState(() {
      _loadingGas = true;
    });

    try {
      final readings = await _gasService.getLatestReadings();
      setState(() {
        _gasReadings = readings;
        _loadingGas = false;
      });
    } catch (error) {
      setState(() {
        _loadingGas = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading gas data: $error')),
        );
      }
    }
  }

  void _setupRealtimeListeners() {
    // Set up the real-time listeners for DHT11
    _subscriptions.add(
      _dht11Service.latestReadingStream.listen((reading) {
        // Don't update UI directly, batch updates instead
        if (_dht11Readings.isEmpty || reading.id != _dht11Readings.first.id) {
          _pendingDHT11Updates.add(reading);
          _hasNewData = true;
        }
      }),
    );

    // Similar for noise and gas
    _subscriptions.add(
      _noiseService.latestReadingStream.listen((reading) {
        if (mounted) {
          // Don't update UI directly, batch updates instead
          _pendingNoiseUpdates.add(reading);
          _hasNewData = true;
        }
      }),
    );

    _subscriptions.add(
      _gasService.latestReadingStream.listen((reading) {
        if (mounted) {
          // Don't update UI directly, batch updates instead
          _pendingGasUpdates.add(reading);
          _hasNewData = true;
        }
      }),
    );

    // Start subscriptions in each service
    _dht11Service.subscribeToLatestReading();
    _noiseService.subscribeToLatestReading();
    _gasService.subscribeToLatestReading();
  }

  @override
  Widget build(BuildContext context) {
    final refreshService = Provider.of<RefreshService>(context);
    final bool isLoading = _loadingDHT11 || _loadingNoise || _loadingGas;
    final bool hasData =
        _dht11Readings.isNotEmpty ||
        _noiseReadings.isNotEmpty ||
        _gasReadings.isNotEmpty;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Environmental Monitoring'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // Only keeping the refresh button
            IconButton(
              icon: refreshService.refreshInProgress
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: () => refreshService.triggerFullRefresh(),
              tooltip: 'Refresh all data',
            ),
          ],
          bottom: TabBar(
            // Set these properties to improve alignment
            labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            tabAlignment: TabAlignment.fill, // Make tabs fill the width
            indicatorSize:
                TabBarIndicatorSize.tab, // Indicator matches tab width
            tabs: const [
              Tab(
                icon: Icon(Icons.dashboard),
                text: 'Overview',
                iconMargin: EdgeInsets.only(bottom: 4.0), // Consistent spacing
              ),
              Tab(
                icon: Icon(Icons.thermostat),
                text: 'Temp.',
                iconMargin: EdgeInsets.only(bottom: 4.0),
              ),
              Tab(
                icon: Icon(Icons.volume_up),
                text: 'Noise',
                iconMargin: EdgeInsets.only(bottom: 4.0),
              ),
              Tab(
                icon: Icon(Icons.air),
                text: 'Gas',
                iconMargin: EdgeInsets.only(bottom: 4.0),
              ),
            ],
            isScrollable: false, // Set to false to make tabs equal width
          ),
        ),
        body: isLoading
            ? const LoadingView()
            : !hasData
            ? const EmptyDataView()
            : TabBarView(
                children: [
                  // Overview Tab
                  OverviewDashboard(
                    latestDHT11: _dht11Readings.isNotEmpty
                        ? _dht11Readings.first
                        : null,
                    latestNoise: _noiseReadings.isNotEmpty
                        ? _noiseReadings.first
                        : null,
                    latestGas: _gasReadings.isNotEmpty
                        ? _gasReadings.first
                        : null,
                    lastUpdated: _lastUpdated,
                    onRefresh: _fetchAllData,
                  ),

                  // DHT11 Tab
                  _dht11Readings.isEmpty
                      ? const EmptyDataView()
                      : DHT11DataView(
                          readings: _dht11Readings,
                          onRefresh: _fetchDHT11Data,
                        ),

                  // Noise Tab
                  _noiseReadings.isEmpty
                      ? const EmptyDataView()
                      : NoiseDataView(
                          readings: _noiseReadings,
                          onRefresh: _fetchNoiseData,
                        ),

                  // Gas Tab
                  _gasReadings.isEmpty
                      ? const EmptyDataView()
                      : GasDataView(
                          readings: _gasReadings,
                          onRefresh: _fetchGasData,
                        ),
                ],
              ),
      ),
    );
  }

  /// Format the time in a readable way
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _updateUITimer?.cancel();
    // Cancel all subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }

    _dht11Service.dispose();
    _noiseService.dispose();
    _gasService.dispose();

    super.dispose();
  }
}
