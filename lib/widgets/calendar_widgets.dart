import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarHeader extends StatelessWidget {
  final DateTime focusedMonth;
  final VoidCallback onLeftChevronTap;
  final VoidCallback onRightChevronTap;

  const CalendarHeader({
    super.key,
    required this.focusedMonth,
    required this.onLeftChevronTap,
    required this.onRightChevronTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(focusedMonth),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.chevron_left, color: theme.primaryColor),
            onPressed: onLeftChevronTap,
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: theme.primaryColor),
            onPressed: onRightChevronTap,
          ),
        ],
      ),
    );
  }
}

class OldCalendarView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final Function(DateTime focusedDay)? onPageChanged;

  const OldCalendarView({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      headerVisible: false,
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: isDark ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        // Changed todayDecoration to a border to avoid color conflicts when selected
        todayDecoration: BoxDecoration(
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5), width: 2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
        defaultTextStyle: TextStyle(color: theme.primaryColor),
        weekendTextStyle: const TextStyle(color: Colors.redAccent),
        outsideTextStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.3)),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold),
        weekendStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
    );
  }
}
