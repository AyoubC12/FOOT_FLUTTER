import 'package:intl/intl.dart';

abstract final class AppFormatters {
  static final date = DateFormat('EEE d MMM');
  static final time = DateFormat.Hm();

  static String percent(double value) =>
      '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%';
}
