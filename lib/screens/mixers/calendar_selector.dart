import 'package:compounders/providers/mixers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// `CalendarSelector` is a widget that allows users to select a date from a calendar view.
///
/// This widget watches the current date state using Riverpod's `dateProvider` and displays
/// a calendar for the current month. It provides navigation for going back and forth between
/// months and handles date selection, updating the state accordingly.
///
/// The calendar UI is composed of a grid that represents the days of the month, allowing
/// the user to tap on a day to select it. Days from the previous or next months are not displayed.
///
/// The widget uses a Scaffold with a black background and a compact AppBar to navigate
/// back or to switch between months.
///
/// Parameters:
///   - `key`: A [Key] used to identify this widget within the widget tree.
class CalendarSelector extends ConsumerWidget {
  /// Constructs a `CalendarSelector` widget.
  const CalendarSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDate = ref.watch(dateProvider);

    final weekdays = ['M', 'T', 'W', 'Th', 'F', 'Sa', 'Su'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(35),
        child: AppBar(
          backgroundColor: Colors.black,
          leadingWidth: 12,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18), // Use arrow_back_ios for a smaller arrow
            onPressed: () {
              GoRouter.of(context).pop();
            },

          ),
          title: Text(DateFormat('MMMM').format(currentDate), style: const TextStyle(fontSize: 8)),
          actions: [
            Transform.scale(
              scale: 0.8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 15),
                onPressed: () {
                  final prevMonth = DateTime(currentDate.year, currentDate.month - 1);
                  ref.read(dateProvider.notifier).state = prevMonth;
                },
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: IconButton(
                iconSize: 15,
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 15,
                ),
                onPressed: () {
                  final nextMonth = DateTime(currentDate.year, currentDate.month + 1);
                  ref.read(dateProvider.notifier).state = nextMonth;
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays
                  .map((day) => Expanded(
                      child:
                          Center(child: Text(day, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))))
                  .toList(),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemBuilder: (context, index) {
                  final firstDayOfTheMonth = DateTime(currentDate.year, currentDate.month);
                  final startingWeekday = firstDayOfTheMonth.weekday; // 1 = Monday, 7 = Sunday

                  if (index < startingWeekday - 1) {
                    return Container(); // Empty container for offset
                  }

                  final day = index - startingWeekday + 2;
                  final displayDate = DateTime(currentDate.year, currentDate.month, day);

                  // Check if the day is beyond the last day of the month
                  if (day > DateTime(currentDate.year, currentDate.month + 1, 0).day) {
                    return Container(); // Empty container
                  }


                  return GestureDetector(
                    onTap: () {
                      ref.read(dateProvider.notifier).state = displayDate;
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSameDay(displayDate, currentDate) ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            color: isSameDay(displayDate, currentDate) ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
