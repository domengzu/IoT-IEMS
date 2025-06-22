import 'package:flutter/material.dart';
import '../../models/settings_model.dart';

class SettingsView extends StatefulWidget {
  final Function(AppSettings) onSettingsChanged;

  const SettingsView({Key? key, required this.onSettingsChanged})
    : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late AppSettings _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettings.load();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _settings.save();
    widget.onSettingsChanged(_settings);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNotificationSection(),
          const Divider(height: 32),
          _buildThresholdSection(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await _saveSettings();
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Settings saved')));
              }
            },
            child: const Text('Save Settings'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              setState(() {
                _settings = AppSettings(); // Reset to defaults
              });
              await _saveSettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              }
            },
            child: const Text('Reset to Defaults'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text('Receive alerts for hazardous conditions'),
          value: _settings.notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _settings.notificationsEnabled = value;
            });
          },
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(height: 8),
                const Text(
                  'Notifications will appear when environmental conditions exceed the thresholds set below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alert Thresholds',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildThresholdSlider(
          label: 'Heat Index Threshold',
          description: 'Alert when heat index exceeds this value (°C)',
          value: _settings.temperatureThreshold,
          min: 30.0,
          max: 50.0,
          divisions: 20,
          onChanged: (value) {
            setState(() {
              _settings.temperatureThreshold = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildThresholdSlider(
          label: 'Noise Level Threshold',
          description: 'Alert when noise exceeds this value (dB)',
          value: _settings.noiseThreshold,
          min: 70.0,
          max: 120.0,
          divisions: 50,
          onChanged: (value) {
            setState(() {
              _settings.noiseThreshold = value;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildThresholdSlider(
          label: 'Gas Concentration Threshold',
          description: 'Alert when gas level exceeds this value (ppm)',
          value: _settings.gasThreshold,
          min: 200.0,
          max: 1000.0,
          divisions: 80,
          onChanged: (value) {
            setState(() {
              _settings.gasThreshold = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.amber.shade50,
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(height: 8),
                Text(
                  'These are alert thresholds, not safety limits. Lower values will trigger more frequent notifications.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdSlider({
    required String label,
    required String description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Row(
          children: [
            Text(
              min.toStringAsFixed(1),
              style: TextStyle(color: Colors.grey[600]),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: value.toStringAsFixed(1),
                onChanged: onChanged,
              ),
            ),
            Text(
              max.toStringAsFixed(1),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Current: ${value.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
