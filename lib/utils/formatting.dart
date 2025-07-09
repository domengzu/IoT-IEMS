class FormatUtils {
  static String toFixed2Decimals(double value) {
    String valueStr = value.toString();

    List<String> parts = valueStr.split('.');
    String wholePart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    if (decimalPart.isEmpty) {
      decimalPart = '00';
    } else if (decimalPart.length == 1) {
      decimalPart = '${decimalPart}0';
    } else if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    return '$wholePart.$decimalPart';
  }
}
