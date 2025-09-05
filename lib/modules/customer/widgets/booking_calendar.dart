import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/service_types.dart';

class BookingCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final List<DateTime> availableDates;

  const BookingCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.availableDates,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TableCalendar<DateTime>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 30)),
              focusedDay: selectedDate,
              selectedDayPredicate: (day) => isSameDay(selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (ServiceTypes.isValidBookingDate(selectedDay)) {
                  onDateSelected(selectedDay);
                }
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: Colors.grey),
                holidayTextStyle: const TextStyle(color: Colors.grey),
                defaultTextStyle: const TextStyle(color: Colors.black),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFFCF2049),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFFCF2049).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFCF2049),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCF2049),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: Color(0xFFCF2049),
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Color(0xFFCF2049),
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCF2049),
                ),
                weekendStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final isAvailable = ServiceTypes.isValidBookingDate(day);
                  final isToday = isSameDay(day, DateTime.now());
                  final isSelected = isSameDay(day, selectedDate);

                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFCF2049)
                          : isToday
                          ? const Color(0xFFCF2049).withOpacity(0.3)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isAvailable
                              ? Colors.black
                              : Colors.grey,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFCF2049).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFCF2049), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sundays are closed. You can book up to 30 days in advance.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFCF2049)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
