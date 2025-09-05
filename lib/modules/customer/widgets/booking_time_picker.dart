import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class BookingTimePicker extends StatefulWidget {
  final String? selectedTime;
  final Function(String) onTimeSelected;
  final List<String> availableTimes;

  const BookingTimePicker({
    super.key,
    this.selectedTime,
    required this.onTimeSelected,
    required this.availableTimes,
  });

  @override
  State<BookingTimePicker> createState() => _BookingTimePickerState();
}

class _BookingTimePickerState extends State<BookingTimePicker> {
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.selectedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.availableTimes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'No available time slots for this date',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: [
                  // Time Picker Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showTimePicker,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime ?? 'Select Time',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedTime != null
                            ? const Color(0xFFCF2049)
                            : Colors.grey[200],
                        foregroundColor: _selectedTime != null
                            ? Colors.white
                            : Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quick Time Selection
                  const Text(
                    'Quick Select:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                                         children: widget.availableTimes.map((time) {
                       // Extract start time for display
                       final displayTime = time.split('-')[0];
                       final isSelected = _selectedTime == displayTime;
                       return GestureDetector(
                         onTap: () {
                           setState(() {
                             _selectedTime = displayTime;
                           });
                           widget.onTimeSelected(time);
                         },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFCF2049)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFCF2049)
                                  : Colors.grey[300]!,
                            ),
                          ),
                                                     child: Text(
                             displayTime,
                             style: TextStyle(
                               color: isSelected ? Colors.white : Colors.black87,
                               fontWeight: isSelected
                                   ? FontWeight.bold
                                   : FontWeight.normal,
                             ),
                           ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Select Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.availableTimes.length,
                                     itemBuilder: (context, index) {
                     final time = widget.availableTimes[index];
                     final displayTime = time.split('-')[0];
                     final isSelected = _selectedTime == displayTime;

                     return ListTile(
                       title: Text(
                         displayTime,
                         style: TextStyle(
                           fontWeight: isSelected
                               ? FontWeight.bold
                               : FontWeight.normal,
                           color: isSelected
                               ? const Color(0xFFCF2049)
                               : Colors.black87,
                         ),
                       ),
                       trailing: isSelected
                           ? const Icon(Icons.check, color: Color(0xFFCF2049))
                           : null,
                       onTap: () {
                         setState(() {
                           _selectedTime = displayTime;
                         });
                         widget.onTimeSelected(time);
                         Navigator.pop(context);
                       },
                     );
                   },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
