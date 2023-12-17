import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/timezone.dart';

class CycleDateRange {
  CycleDateRange(this.startDate, this.endDate);
  DateTime startDate;
  DateTime endDate;
}

CycleDateRange getCurrentCycleDateRange(DateTime today) {
  DateTime getLastThursday(DateTime monthYear) {
    var lastDay = DateTime(monthYear.year, monthYear.month + 1, 0); // Last day of the month
    // Go back from the last day of the month until it's Thursday
    while (lastDay.weekday != DateTime.thursday) {
      lastDay = lastDay.subtract(const Duration(days: 1));
    }
    return lastDay;
  }

  final lastThursdayThisMonth = getLastThursday(today);
  final lastThursdayPrevMonth = getLastThursday(DateTime(today.year, today.month - 1));
  final lastThursdayNextMonth = getLastThursday(DateTime(today.year, today.month + 1));

  if (today.isBefore(lastThursdayThisMonth) || today.isAtSameMomentAs(lastThursdayThisMonth)) {
    return CycleDateRange(lastThursdayPrevMonth.add(const Duration(days: 1)), lastThursdayThisMonth);
  } else {
    return CycleDateRange(lastThursdayThisMonth.add(const Duration(days: 1)), lastThursdayNextMonth);
  }
}

DateTime getLastThursdayOfMonth(DateTime date) {
  final lastDayOfMonth = DateTime(date.year, date.month + 1, 0); // This gets the last day of the month.
  // We'll go back in days from the last day until we find a Thursday.
  for (var i = 0; i < 7; i++) {
    if (lastDayOfMonth.subtract(Duration(days: i)).weekday == DateTime.thursday) {
      return lastDayOfMonth.subtract(Duration(days: i));
    }
  }
  throw Exception('Could not find last Thursday of the month'); // This line should never be reached.
}

TZDateTime getCurrentLocalTime() {
  final localLocation = tz.local;
  final now = tz.TZDateTime.now(localLocation);
  return now;
}

double formatPrecision(double value, [int precision = 3]) => num.parse(value.toStringAsFixed(precision)).toDouble();

class FirestoreException implements Exception {
  FirestoreException(this.code);

  final String code;

  @override
  String toString() => 'FirestoreException: $code';
}

class NetworkError implements Error {

  NetworkError(this.message);
  final String message;

  @override
  String toString() => 'NetworkError: $message';

  @override
  // TODO: implement stackTrace
  StackTrace? get stackTrace => throw UnimplementedError();
}

class MixerStreamException implements Exception {
  MixerStreamException(this.message);
  final String message;

  @override
  String toString() => message;
}

class MixerNetworkException extends MixerStreamException {
  MixerNetworkException(super.message);
}

class MixerFormatException extends MixerStreamException {
  MixerFormatException(super.message);
}
