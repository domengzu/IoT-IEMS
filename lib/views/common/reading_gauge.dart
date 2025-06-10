import 'package:flutter/material.dart';

class ReadingGauge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const ReadingGauge({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
      ],
    );
  }
}
