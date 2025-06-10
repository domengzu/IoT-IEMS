import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/sensor_reading.dart';
import '../../../utils/formatting.dart';

import 'dart:math' as math;
import 'dart:ui' as ui;

class ChartUtils {
  /// Creates a line chart for sensor readings
  static Widget createLineChart<T extends SensorReading>({
    required BuildContext context,
    required List<T> data,
    required double Function(T) getValue,
    required DateTime Function(T) getTime,
    required String timeRange,
    required Color color,
    required String title,
    required String yAxisLabel,
  }) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Sort data by timestamp
    final sortedData = [...data]
      ..sort((a, b) => getTime(a).compareTo(getTime(b)));

    // Filter data points to avoid overcrowding
    final filteredData = _getFilteredDataPoints(sortedData, timeRange);

    // Calculate min, max, avg for display
    final min = filteredData.map(getValue).reduce((a, b) => a < b ? a : b);
    final max = filteredData.map(getValue).reduce((a, b) => a > b ? a : b);
    final avg =
        filteredData.map(getValue).reduce((a, b) => a + b) /
        filteredData.length;

    // Prepare data for chart
    final chartData = filteredData
        .map(
          (reading) => {'value': getValue(reading), 'time': getTime(reading)},
        )
        .toList();

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and time range
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    // Changed from headline6
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant ?? Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    timeRange,
                    style: textTheme.bodySmall?.copyWith(
                      // Changed from caption
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
              style: textTheme.bodySmall?.copyWith(
                // Changed from caption
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            // Stats cards
            Row(
              children: [
                _buildEnhancedStatCard(
                  context,
                  'Minimum',
                  FormatUtils.toFixed2Decimals(min),
                  Icons.arrow_downward,
                  Colors.blue,
                ),
                _buildEnhancedStatCard(
                  context,
                  'Average',
                  FormatUtils.toFixed2Decimals(avg),
                  Icons.bar_chart,
                  Colors.amber.shade700,
                ),
                _buildEnhancedStatCard(
                  context,
                  'Maximum',
                  FormatUtils.toFixed2Decimals(max),
                  Icons.arrow_upward,
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Y-axis label
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Text(
                yAxisLabel,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            // Chart
            Expanded(
              child: EnhancedLineChart(
                data: chartData,
                color: color,
                maxValue: max * 1.1, // Add 10% padding
                minValue: min * 0.9, // Subtract 10% padding
                timeRange: timeRange,
                isDarkMode: Theme.of(context).brightness == Brightness.dark,
                baseTextColor: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced stat card with better visual design and improved readability
  static Widget _buildEnhancedStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Create a gradient background for better visual appeal
    final gradientColors = [
      color.withOpacity(isDarkMode ? 0.15 : 0.12),
      color.withOpacity(isDarkMode ? 0.08 : 0.05),
    ];

    // Adjust text color based on background for better readability
    final labelColor = isDarkMode
        ? Colors.white.withOpacity(0.9)
        : colorScheme.onSurface.withOpacity(0.8);

    final valueColor = color.computeLuminance() > 0.5 && !isDarkMode
        ? Color.lerp(color, Colors.black, 0.4)!
        : Color.lerp(color, Colors.white, isDarkMode ? 0.3 : 0.0)!;

    return Expanded(
      child: Card(
        elevation: 3,
        shadowColor: color.withOpacity(0.3),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2), width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Column(
            children: [
              // Label row with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Value with drop shadow for better visibility
              Stack(
                children: [
                  // Text shadow for better visibility on any background
                  Text(
                    value,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withOpacity(0.25),
                      height: 1.0,
                    ),
                  ),

                  // Main text
                  Text(
                    value,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to filter data points to avoid overcrowded charts
  static List<T> _getFilteredDataPoints<T extends SensorReading>(
    List<T> data,
    String timeRange,
  ) {
    if (data.length <= 30) return data;

    // For larger datasets, sample points to make chart more readable
    int interval;
    switch (timeRange) {
      case '1 hour':
        interval = data.length ~/ 20;
        break;
      case '6 hours':
        interval = data.length ~/ 25;
        break;
      case '24 hours':
        interval = data.length ~/ 30;
        break;
      default:
        interval = data.length ~/ 40;
    }

    interval = interval < 1 ? 1 : interval;

    // Keep first, last and sampled points
    List<T> result = [data.first];
    for (int i = interval; i < data.length - interval; i += interval) {
      result.add(data[i]);
    }
    result.add(data.last);

    return result;
  }
}

// Renamed to better reflect enhanced visuals
class EnhancedLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final Color color;
  final double maxValue;
  final double minValue;
  final String timeRange;
  final bool isDarkMode;
  final Color baseTextColor;

  const EnhancedLineChart({
    super.key,
    required this.data,
    required this.color,
    required this.maxValue,
    required this.minValue,
    required this.timeRange,
    this.isDarkMode = false,
    this.baseTextColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(50, 20, 20, 40),
            child: CustomPaint(
              size: Size(constraints.maxWidth - 70, constraints.maxHeight - 60),
              painter: EnhancedLineChartPainter(
                data: data,
                color: color,
                maxValue: maxValue,
                minValue: minValue,
                timeRange: timeRange,
                isDarkMode: isDarkMode,
                textColor: baseTextColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class EnhancedLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color color;
  final double maxValue;
  final double minValue;
  final String timeRange;
  final bool isDarkMode;
  final Color textColor;

  EnhancedLineChartPainter({
    required this.data,
    required this.color,
    required this.maxValue,
    required this.minValue,
    required this.timeRange,
    this.isDarkMode = false,
    this.textColor = Colors.black87,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Enhanced colors for better readability
    final primaryColor = color;
    final gridColor = isDarkMode
        ? Colors.grey[700]!.withOpacity(0.3)
        : Colors.grey[300]!; // Added semicolon here
    final labelColor = isDarkMode ? Colors.grey[300]! : textColor;

    final Paint linePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [
        primaryColor.withOpacity(0.4),
        primaryColor.withOpacity(0.05),
      ])
      ..style = PaintingStyle.fill;

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint dashPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw background grid
    _drawGrid(canvas, size, gridPaint);

    // Draw data line and fill
    _drawLineAndFill(canvas, size, linePaint, fillPaint);

    // Draw points on the line
    _drawDataPoints(canvas, size, primaryColor);

    // Draw axis labels with improved styling
    _drawAxisLabels(canvas, size, labelColor);
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    // Draw horizontal grid lines (5 lines)
    for (int i = 0; i < 6; i++) {
      final y = size.height - (size.height * i / 5);

      // Use dashed lines for better visual separation
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw vertical grid lines (5 lines)
    for (int i = 0; i < 6; i++) {
      final x = size.width * i / 5;

      // Use dashed lines for better visual separation
      _drawDashedLine(canvas, Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4;
    const dashSpace = 4;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final count = math.sqrt(dx * dx + dy * dy) / (dashWidth + dashSpace);

    final dx1 = dx / count;
    final dy1 = dy / count;

    var x1 = start.dx;
    var y1 = start.dy;

    for (var i = 0; i < count; i++) {
      canvas.drawLine(Offset(x1, y1), Offset(x1 + dx1, y1 + dy1), paint);

      x1 += dx1 + dx1; // Skip the space
      y1 += dy1 + dy1;
    }
  }

  void _drawLineAndFill(
    Canvas canvas,
    Size size,
    Paint linePaint,
    Paint fillPaint,
  ) {
    final path = Path();
    final fillPath = Path();

    // Map data points to coordinates
    final points = _getPointCoordinates(size);

    if (points.isEmpty) return;

    // Use cubic bezier curves for smoother line
    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    if (points.length < 3) {
      // If few points, use simple lines
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
    } else {
      // Use bezier curves for smoother line with many points
      for (int i = 0; i < points.length - 2; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final p2 = points[i + 2];

        final xc1 = (p0.dx + p1.dx) / 2;
        final yc1 = (p0.dy + p1.dy) / 2;
        final xc2 = (p1.dx + p2.dx) / 2;
        final yc2 = (p1.dy + p2.dy) / 2;

        path.quadraticBezierTo(p1.dx, p1.dy, xc2, yc2);
        fillPath.quadraticBezierTo(p1.dx, p1.dy, xc2, yc2);
      }

      // Add the last two points
      if (points.length >= 2) {
        path.lineTo(points[points.length - 1].dx, points[points.length - 1].dy);
        fillPath.lineTo(
          points[points.length - 1].dx,
          points[points.length - 1].dy,
        );
      }
    }

    // Complete fill path to bottom right
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Draw fill first (underneath line)
    canvas.drawPath(fillPath, fillPaint);

    // Then draw line on top
    canvas.drawPath(path, linePaint);
  }

  void _drawDataPoints(Canvas canvas, Size size, Color color) {
    final points = _getPointCoordinates(size);
    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Only draw points if there are not too many
    if (points.length <= 20) {
      for (var point in points) {
        // Outer circle
        canvas.drawCircle(point, 4, outerPaint);
        // Inner circle
        canvas.drawCircle(point, 2, innerPaint);
      }
    } else {
      // For more points, only draw endpoints
      canvas.drawCircle(points.first, 4, outerPaint);
      canvas.drawCircle(points.first, 2, innerPaint);
      canvas.drawCircle(points.last, 4, outerPaint);
      canvas.drawCircle(points.last, 2, innerPaint);
    }
  }

  List<Offset> _getPointCoordinates(Size size) {
    if (data.isEmpty) return [];

    // Get the time range as milliseconds
    final firstTime = (data.first['time'] as DateTime).millisecondsSinceEpoch;
    final lastTime = (data.last['time'] as DateTime).millisecondsSinceEpoch;
    final timeRange = lastTime - firstTime;

    if (timeRange == 0) return [Offset(size.width / 2, size.height / 2)];

    return data.map((point) {
      // Map x-coordinate (time) to canvas space
      final time = (point['time'] as DateTime).millisecondsSinceEpoch;
      final x = (time - firstTime) / timeRange * size.width;

      // Map y-coordinate (value) to canvas space
      final value = point['value'] as double;
      final valueRange = maxValue - minValue;

      if (valueRange == 0) return Offset(x, size.height / 2);

      final normalizedValue = (value - minValue) / valueRange;
      final y = size.height - (normalizedValue * size.height);

      return Offset(x, y);
    }).toList();
  }

  void _drawAxisLabels(Canvas canvas, Size size, Color textColor) {
    final textStyle = TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // Draw y-axis values with improved visibility
    for (int i = 0; i < 6; i++) {
      final value = minValue + ((maxValue - minValue) * i / 5);
      final y = size.height - (size.height * i / 5);

      // Draw label background for better visibility
      final String valueText = value.toStringAsFixed(1);
      textPainter.text = TextSpan(text: valueText, style: textStyle);

      textPainter.layout();

      // Draw background rectangle
      final rect = Rect.fromLTWH(
        -textPainter.width - 8,
        y - textPainter.height / 2 - 2,
        textPainter.width + 6,
        textPainter.height + 4,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()
          ..color = isDarkMode
              ? Colors.grey[800]!.withOpacity(0.7)
              : Colors.white.withOpacity(0.9)
          ..style = PaintingStyle.fill,
      );

      textPainter.paint(
        canvas,
        Offset(-textPainter.width - 5, y - textPainter.height / 2),
      );
    }

    // Draw x-axis time values with improved visibility
    if (data.length >= 2) {
      final firstTime = data.first['time'] as DateTime;
      final lastTime = data.last['time'] as DateTime;

      // Format based on time range
      final format = _getTimeFormat();

      // Draw first and last time labels
      _drawEnhancedTimeLabel(
        canvas,
        firstTime,
        0,
        size.height,
        format,
        textStyle,
        textPainter,
      );
      _drawEnhancedTimeLabel(
        canvas,
        lastTime,
        size.width,
        size.height,
        format,
        textStyle,
        textPainter,
      );

      // Draw middle time labels
      for (int i = 1; i < 5; i++) {
        final fraction = i / 5;
        final diffMillis =
            lastTime.millisecondsSinceEpoch - firstTime.millisecondsSinceEpoch;
        final time = DateTime.fromMillisecondsSinceEpoch(
          (firstTime.millisecondsSinceEpoch + (diffMillis * fraction)).round(),
        );

        _drawEnhancedTimeLabel(
          canvas,
          time,
          size.width * fraction,
          size.height,
          format,
          textStyle,
          textPainter,
        );
      }
    }
  }

  void _drawEnhancedTimeLabel(
    Canvas canvas,
    DateTime time,
    double x,
    double y,
    String format,
    TextStyle style,
    TextPainter painter,
  ) {
    painter.text = TextSpan(
      text: DateFormat(format).format(time),
      style: style,
    );

    painter.layout();

    // Draw background rectangle for better visibility
    final rect = Rect.fromLTWH(
      x - painter.width / 2 - 3,
      y + 3,
      painter.width + 6,
      painter.height + 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..color = isDarkMode
            ? Colors.grey[800]!.withOpacity(0.7)
            : Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );

    painter.paint(canvas, Offset(x - painter.width / 2, y + 5));
  }

  String _getTimeFormat() {
    switch (timeRange) {
      case '1 hour':
      case '6 hours':
        return 'HH:mm';
      case '24 hours':
        return 'HH:mm';
      case '7 days':
        return 'MM/dd';
      default:
        return 'MM/dd';
    }
  }

  @override
  bool shouldRepaint(EnhancedLineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.minValue != minValue ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
