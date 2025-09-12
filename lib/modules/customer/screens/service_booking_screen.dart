import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/shop_service.dart';
import '../../../core/constants/service_types.dart';
import '../../../shared/models/shop_availability_model.dart';
import '../../../shared/models/time_slot_model.dart';
import '../../../core/navigation/route_names.dart';
import '../widgets/multi_service_selector.dart';
import '../widgets/booking_calendar.dart';
import '../widgets/booking_time_picker.dart';

class ServiceBookingScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const ServiceBookingScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  final BookingService _bookingService = BookingService();
  final ShopService _shopService = ShopService();

  DateTime _selectedDate = DateTime.now();
  String? _selectedStartTime;
  List<String> _selectedServices = [];
  String? _selectedVehicleId;
  String _notes = '';

  bool _isLoading = false;
  String? _errorMessage;
  ShopAvailability? _shopAvailability;
  List<String> _availableServices = [];

  @override
  void initState() {
    super.initState();
    _loadShopAvailability();
    _loadShopServices();
  }

  Future<void> _loadShopAvailability() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the new improved method that filters past slots and sorts chronologically
      final availableSlots = await _bookingService
          .getAvailableTimeSlotsForBooking(
            widget.shopId,
            _formatDate(_selectedDate),
          );

      print('🔍 Available time slots loaded: ${availableSlots.length} slots');
      print('🔍 Available slots: $availableSlots');

      // Create a mock availability object for compatibility
      final availability = ShopAvailability(
        shopId: widget.shopId,
        date: _formatDate(_selectedDate),
        timeSlots: {},
        lastUpdated: DateTime.now(),
      );

      // Convert string slots to TimeSlot objects
      for (String slot in availableSlots) {
        availability.timeSlots[slot] = TimeSlot(
          time: slot,
          isAvailable: true,
          bookingId: null,
          serviceTypes: null,
        );
      }

      setState(() {
        _shopAvailability = availability;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading shop availability: $e');
      setState(() {
        _errorMessage = 'Failed to load availability: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadShopServices() async {
    try {
      final services = await _shopService.getShopServices(widget.shopId);
      setState(() {
        _availableServices = services;
      });
      print('✅ Loaded shop services: $services');
    } catch (e) {
      print('❌ Error loading shop services: $e');
      setState(() {
        _availableServices = [];
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _bookAppointment() async {
    if (_selectedStartTime == null || _selectedServices.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a time and at least one service';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final booking = await _bookingService.bookAppointment(
        shopId: widget.shopId,
        date: _formatDate(_selectedDate),
        startTime: _selectedStartTime!,
        serviceTypes: _selectedServices,
        vehicleId: _selectedVehicleId,
        notes: _notes.isEmpty ? null : _notes,
      );

      if (booking != null && mounted) {
        // Show snackbar for immediate feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(RouteNames.schedule);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to book appointment: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Service - ${widget.shopName}'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _shopAvailability == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                  _buildServiceSelector(),
                  const SizedBox(height: 24),
                  _buildTimeSlotSelector(),
                  const SizedBox(height: 24),
                  _buildNotesField(),
                  const SizedBox(height: 24),
                  _buildBookingSummary(),
                  const SizedBox(height: 24),
                  _buildBookButton(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    return BookingCalendar(
      selectedDate: _selectedDate,
      onDateSelected: (date) {
        setState(() {
          _selectedDate = date;
          _selectedStartTime = null;
        });
        _loadShopAvailability();
      },
      availableDates: ServiceTypes.getAvailableDates(),
    );
  }

  Widget _buildServiceSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Services',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            MultiServiceSelector(
              selectedServices: _selectedServices,
              availableServices: _availableServices,
              onServicesChanged: (services) {
                setState(() {
                  _selectedServices = services;
                  _selectedStartTime = null; // Reset time selection
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelector() {
    if (_selectedServices.isEmpty) {
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Please select services first to see available time slots',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final availableSlots = _shopAvailability?.availableSlots ?? [];
    final availableTimes = availableSlots
        .where((slot) => slot.isAvailable)
        .map((slot) => slot.time) // Use slot.time instead of slot.startTime
        .toList();

    return BookingTimePicker(
      selectedTime: _selectedStartTime,
      onTimeSelected: (time) {
        setState(() {
          // Extract start time from time slot format "10:00-10:30" -> "10:00"
          _selectedStartTime = time.split('-')[0];
        });
      },
      availableTimes: availableTimes,
    );
  }

  Widget _buildNotesField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any special requests or notes for the service...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _notes = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    if (_selectedStartTime == null || _selectedServices.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalDuration = ServiceTypes.calculateTotalDuration(
      _selectedServices,
    );
    final estimatedCost = ServiceTypes.calculateTotalCost(_selectedServices);
    final endTime = _calculateEndTime(_selectedStartTime!, totalDuration);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Shop', widget.shopName),
            _buildSummaryRow('Date', _formatDate(_selectedDate)),
            _buildSummaryRow('Time', '$_selectedStartTime - $endTime'),
            _buildSummaryRow('Duration', '${totalDuration} minutes'),
            _buildSummaryRow('Services', _selectedServices.join(', ')),
            _buildSummaryRow(
              'Estimated Cost',
              '\$${estimatedCost.toStringAsFixed(2)}',
            ),
            if (_notes.isNotEmpty) _buildSummaryRow('Notes', _notes),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    final canBook =
        _selectedStartTime != null &&
        _selectedServices.isNotEmpty &&
        !_isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canBook ? _bookAppointment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCF2049),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Book Appointment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateEndTime(String startTime, int duration) {
    final start = _timeToMinutes(startTime);
    final end = start + duration;
    final endHour = end ~/ 60;
    final endMinute = end % 60;
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
