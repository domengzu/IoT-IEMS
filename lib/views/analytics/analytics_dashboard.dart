import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/sensor_reading.dart'; // Add this import
import '../../services/dht11_service.dart';
import '../../services/noise_service.dart';
import '../../services/gas_service.dart';
import '../../models/dht11_reading.dart';
import '../../models/noise_reading.dart';
import '../../models/gas_reading.dart';
import '../common/loading_view.dart';
import '../common/empty_view.dart';
import 'charts/temperature_chart.dart';
import 'charts/humidity_chart.dart';
import 'charts/noise_chart.dart';
import 'charts/gas_chart.dart';
import '../../services/refresh_service.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final DHT11Service _dht11Service;
  late final NoiseService _noiseService;
  late final GasService _gasService;

  List<DHT11Reading> _dht11Readings = [];
  List<NoiseReading> _noiseReadings = [];
  List<GasReading> _gasReadings = [];

  bool _loading = true;
  String _timeRange = '24 hours'; // Default time range

  List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final client = Supabase.instance.client;
    _dht11Service = DHT11Service(client);
    _noiseService = NoiseService(client);
    _gasService = GasService(client);

    _fetchAllData();
    _setupRealtimeListeners();

    // Set up automatic refresh
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();

    // Cancel all subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }

    _dht11Service.dispose();
    _noiseService.dispose();
    _gasService.dispose();

    super.dispose();
  }

  void _setupRealtimeListeners() {
    // Start real-time subscriptions
    _dht11Service.subscribeToLatestReading();
    _noiseService.subscribeToLatestReading();
    _gasService.subscribeToLatestReading();

    // Listen for DHT11 updates and refresh data
    _subscriptions.add(
      _dht11Service.latestReadingStream.listen((reading) {
        // Add the new reading to our list
        if (mounted) {
          setState(() {
            _dht11Readings.insert(0, reading);
            // Optionally limit the list size to prevent memory issues
            if (_dht11Readings.length > 100) {
              _dht11Readings = _dht11Readings.sublist(0, 100);
            }
          });
        }
      }),
    );

    // Listen for noise updates
    _subscriptions.add(
      _noiseService.latestReadingStream.listen((reading) {
        if (mounted) {
          setState(() {
            _noiseReadings.insert(0, reading);
            if (_noiseReadings.length > 100) {
              _noiseReadings = _noiseReadings.sublist(0, 100);
            }
          });
        }
      }),
    );

    // Listen for gas updates
    _subscriptions.add(
      _gasService.latestReadingStream.listen((reading) {
        if (mounted) {
          setState(() {
            _gasReadings.insert(0, reading);
            if (_gasReadings.length > 100) {
              _gasReadings = _gasReadings.sublist(0, 100);
            }
          });
        }
      }),
    );
  }

  void _setupAutoRefresh() {
    // Listen to specific refresh events from the service
    final refreshService = Provider.of<RefreshService>(context, listen: false);
    
    _subscriptions.add(
      refreshService.dht11RefreshStream.listen((_) {
        if (mounted) {
          _fetchDHT11Data();
        }
      })
    );
    
    _subscriptions.add(
      refreshService.noiseRefreshStream.listen((_) {
        if (mounted) {
          _fetchNoiseData();
        }
      })
    );
    
    _subscriptions.add(
      refreshService.gasRefreshStream.listen((_) {
        if (mounted) {
          _fetchGasData();
        }
      })
    );
    
    // Listen for global refreshes too
    _subscriptions.add(
      refreshService.refreshStream.listen((_) {
        if (mounted) {
          _fetchAllData();
        }
      })
    );
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _loading = true;
    });

    try {
      // Fetch more data points for analytics (up to 100)
      final dht11Future = _dht11Service.getLatestReadings(limit: 100);
      final noiseFuture = _noiseService.getLatestReadings(limit: 100);
      final gasFuture = _gasService.getLatestReadings(limit: 100);

      final results = await Future.wait([dht11Future, noiseFuture, gasFuture]);

      setState(() {
        _dht11Readings = results[0] as List<DHT11Reading>;
        _noiseReadings = results[1] as List<NoiseReading>;
        _gasReadings = results[2] as List<GasReading>;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics data: $error')),
        );
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _fetchDHT11Data() async {
    try {
      final readings = await _dht11Service.getLatestReadings(limit: 100);
      if (mounted) {
        setState(() {
          _dht11Readings = readings;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading DHT11 data: $error')),
        );
      }
    }
  }

  void _fetchNoiseData() async {
    try {
      final readings = await _noiseService.getLatestReadings(limit: 100);
      if (mounted) {
        setState(() {
          _noiseReadings = readings;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading noise data: $error')),
        );
      }
    }
  }

  void _fetchGasData() async {
    try {
      final readings = await _gasService.getLatestReadings(limit: 100);
      if (mounted) {
        setState(() {
          _gasReadings = readings;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading gas data: $error')),
        );
      }
    }
  }

  List<T> _filterDataByTimeRange<T extends SensorReading>(List<T> readings) {
    final now = DateTime.now();
    final DateTime cutoffDate;

    switch (_timeRange) {
      case '1 hour':
        cutoffDate = now.subtract(const Duration(hours: 1));
        break;
      case '6 hours':
        cutoffDate = now.subtract(const Duration(hours: 6));
        break;
      case '24 hours':
        cutoffDate = now.subtract(const Duration(hours: 24));
        break;
      case '7 days':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case '30 days':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      default:
        cutoffDate = now.subtract(const Duration(hours: 24));
    }

    return readings
        .where((reading) => reading.timestamp.isAfter(cutoffDate))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')), // Fixed const issue
        body: const LoadingView(),
      );
    }

    final filteredDHT11 = _filterDataByTimeRange(_dht11Readings);
    final filteredNoise = _filterDataByTimeRange(_noiseReadings);
    final filteredGas = _filterDataByTimeRange(_gasReadings);

    final bool hasData =
        filteredDHT11.isNotEmpty ||
        filteredNoise.isNotEmpty ||
        filteredGas.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Date range picker button
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDateRangePicker,
            tooltip: 'Select date range',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAllData,
            tooltip: 'Refresh data',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TabBar(
            controller: _tabController,
            // Improved tab bar styling
            labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            tabAlignment: TabAlignment.fill,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(
                icon: Icon(Icons.thermostat),
                text: 'Temperature',
                iconMargin: EdgeInsets.only(bottom: 4.0),
              ),
              Tab(
                icon: Icon(Icons.water_drop),
                text: 'Humidity',
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
            isScrollable: false, // Set to false for equal width tabs
          ),
        ),
      ),
      body: !hasData
          ? const EmptyDataView()
          : TabBarView(
              controller: _tabController,
              children: [
                // Temperature Tab
                filteredDHT11.isEmpty
                    ? const EmptyDataView()
                    : TemperatureChart(
                        readings: filteredDHT11,
                        timeRange: _timeRange,
                      ),

                // Humidity Tab
                filteredDHT11.isEmpty
                    ? const EmptyDataView()
                    : HumidityChart(
                        readings: filteredDHT11,
                        timeRange: _timeRange,
                      ),

                // Noise Tab
                filteredNoise.isEmpty
                    ? const EmptyDataView()
                    : NoiseChart(
                        readings: filteredNoise,
                        timeRange: _timeRange,
                      ),

                // Gas Tab
                filteredGas.isEmpty
                    ? const EmptyDataView()
                    : GasChart(readings: filteredGas, timeRange: _timeRange),
              ],
            ),
    );
  }

  void _showDateRangePicker() async {
    // Implement your date range picker logic here
    // You can use a package like 'flutter_datetime_picker' or 'showDateRangePicker' from the material library
  }
}
