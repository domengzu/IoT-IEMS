class FormatUtils {
  /// Formats a double to show exactly 2 decimal places without rounding
  /// Example: 27.88 -> "27.88", 27.8 -> "27.80", 27 -> "27.00"
  static String toFixed2Decimals(double value) {
    // Convert to string with many decimal places
    String valueStr = value.toString();

    // Split into whole and decimal parts
    List<String> parts = valueStr.split('.');
    String wholePart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Add trailing zeros or truncate to exactly 2 decimal places
    if (decimalPart.isEmpty) {
      decimalPart = '00';
    } else if (decimalPart.length == 1) {
      decimalPart = '${decimalPart}0';
    } else if (decimalPart.length > 2) {
      // Truncate, don't round
      decimalPart = decimalPart.substring(0, 2);
    }

    return '$wholePart.$decimalPart';
  }
}
