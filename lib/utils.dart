class CycleDateRange {
  DateTime startDate;
  DateTime endDate;

  CycleDateRange(this.startDate, this.endDate);
}

CycleDateRange getCurrentCycleDateRange(DateTime today) {
  DateTime getLastThursday(DateTime monthYear) {
    DateTime lastDay = DateTime(monthYear.year, monthYear.month + 1, 0); // Last day of the month
    // Go back from the last day of the month until it's Thursday
    while (lastDay.weekday != DateTime.thursday) {
      lastDay = lastDay.subtract(const Duration(days: 1));
    }
    return lastDay;
  }

  DateTime lastThursdayThisMonth = getLastThursday(today);
  DateTime lastThursdayPrevMonth = getLastThursday(DateTime(today.year, today.month - 1, 1));
  DateTime lastThursdayNextMonth = getLastThursday(DateTime(today.year, today.month + 1, 1));

  if (today.isBefore(lastThursdayThisMonth) || today.isAtSameMomentAs(lastThursdayThisMonth)) {
    return CycleDateRange(lastThursdayPrevMonth.add(Duration(days: 1)), lastThursdayThisMonth);
  } else {
    return CycleDateRange(lastThursdayThisMonth.add(Duration(days: 1)), lastThursdayNextMonth);
  }
}



DateTime getLastThursdayOfMonth(DateTime date) {
  final lastDayOfMonth = DateTime(date.year, date.month + 1, 0); // This gets the last day of the month.
  // We'll go back in days from the last day until we find a Thursday.
  for (int i = 0; i < 7; i++) {
    if (lastDayOfMonth.subtract(Duration(days: i)).weekday == DateTime.thursday) {
      return lastDayOfMonth.subtract(Duration(days: i));
    }
  }
  throw Exception('Could not find last Thursday of the month'); // This line should never be reached.
}
