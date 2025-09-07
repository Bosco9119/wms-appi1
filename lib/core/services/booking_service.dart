import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/booking_model.dart';
import '../../shared/models/time_slot_model.dart';
import '../../shared/models/shop_availability_model.dart';
import '../constants/service_types.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _bookingsRef => _firestore.collection('bookings');
  CollectionReference get _shopsRef => _firestore.collection('shops');

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Book an appointment with conflict prevention
  Future<Booking?> bookAppointment({
    required String shopId,
    required String date,
    required String startTime,
    required List<String> serviceTypes,
    String? vehicleId,
    String? notes,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Validate date and time
    final bookingDate = DateTime.parse(date);
    if (!ServiceTypes.isValidBookingDate(bookingDate)) {
      throw Exception('Invalid booking date');
    }

    // Check if time slot is in the past
    final timeSlot =
        '${startTime}-${ServiceTypes.generateTimeSlots(startTime, ServiceTypes.calculateTotalDuration(serviceTypes)).last.split('-')[1]}';
    if (ServiceTypes.isTimeSlotInPast(timeSlot, bookingDate)) {
      throw Exception('Cannot book time slots in the past');
    }

    // Calculate total duration and cost
    final totalDuration = ServiceTypes.calculateTotalDuration(serviceTypes);
    final estimatedCost = ServiceTypes.calculateTotalCost(serviceTypes);

    // Generate time slots needed
    final requiredSlots = ServiceTypes.generateTimeSlots(
      startTime,
      totalDuration,
    );

    // Check for existing bookings by the same user for the same time slot
    try {
      final existingBookingQuery = await _bookingsRef
          .where('userId', isEqualTo: _currentUserId!)
          .where('shopId', isEqualTo: shopId)
          .where('date', isEqualTo: date)
          .where('status', isEqualTo: 'confirmed')
          .limit(1)
          .get();

      if (existingBookingQuery.docs.isNotEmpty) {
        final existingBooking = Booking.fromMap(
          existingBookingQuery.docs.first.data() as Map<String, dynamic>,
        );

        // Check if the existing booking overlaps with the requested time
        final existingSlots = ServiceTypes.generateTimeSlots(
          existingBooking.timeSlot.split('-')[0],
          existingBooking.totalDuration,
        );

        for (String slot in requiredSlots) {
          if (existingSlots.contains(slot)) {
            throw Exception('You already have a booking at this time slot');
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('already have a booking')) {
        rethrow;
      }
      print('⚠️ Warning: Could not check for existing bookings: $e');
    }

    try {
      // Use transaction to prevent double booking
      return await _firestore.runTransaction<Booking?>((transaction) async {
        // 1. Check shop availability
        final availabilityRef = _shopsRef
            .doc(shopId)
            .collection('availability')
            .doc(date);

        final availabilityDoc = await transaction.get(availabilityRef);

        if (!availabilityDoc.exists) {
          // Initialize availability for this date
          await _initializeShopAvailability(shopId, date);
          // Re-fetch the document
          final newAvailabilityDoc = await transaction.get(availabilityRef);
          if (!newAvailabilityDoc.exists) {
            throw Exception('Failed to initialize shop availability');
          }
        }

        final availability = ShopAvailability.fromMap(
          availabilityDoc.data()!,
          shopId,
          date,
        );

        // 2. Check if all required slots are available
        for (String slot in requiredSlots) {
          if (!availability.isSlotAvailable(slot)) {
            throw Exception('Time slot $slot is not available');
          }
        }

        // 3. Check for existing bookings by the same user for the same time slot
        // Note: We can't use complex queries in transactions, so we'll check before the transaction
        // This is handled in the bookAppointment method before calling the transaction

        // 4. Get shop and customer details
        final shopDoc = await transaction.get(_shopsRef.doc(shopId));
        if (!shopDoc.exists) {
          throw Exception('Shop not found');
        }

        final shopData = shopDoc.data() as Map<String, dynamic>;
        final customerDoc = await transaction.get(
          _firestore.collection('customers').doc(_currentUserId!),
        );
        if (!customerDoc.exists) {
          throw Exception('Customer not found');
        }

        final customerData = customerDoc.data() as Map<String, dynamic>;

        // 5. Create booking
        final bookingRef = _bookingsRef.doc();
        final booking = Booking(
          id: bookingRef.id,
          shopId: shopId,
          userId: _currentUserId!,
          date: date,
          timeSlot: timeSlot,
          serviceTypes: serviceTypes,
          totalDuration: totalDuration,
          status: BookingStatus.confirmed,
          vehicleId: vehicleId,
          notes: notes,
          estimatedCost: estimatedCost,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          shopName: shopData['name'] ?? 'Unknown Shop',
          shopAddress: shopData['address'] ?? '',
          shopPhone: shopData['phone'] ?? '',
          customerName: customerData['fullName'] ?? 'Unknown Customer',
          customerPhone: customerData['phoneNumber'] ?? '',
          customerEmail: customerData['email'] ?? '',
        );

        // 6. Update availability - mark slots as booked
        final updatedTimeSlots = availability.timeSlots.map(
          (key, value) => MapEntry(key, value.toMap()),
        );
        for (String slot in requiredSlots) {
          updatedTimeSlots[slot] = {
            'isAvailable': false,
            'bookingId': bookingRef.id,
            'serviceTypes': serviceTypes,
          };
        }

        // 7. Execute transaction
        transaction.set(bookingRef, booking.toMap());
        transaction.update(availabilityRef, {
          'timeSlots': updatedTimeSlots,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        return booking;
      });
    } catch (e) {
      print('❌ BookingService Error: $e');
      rethrow;
    }
  }

  /// Get user's bookings
  Future<List<Booking>> getUserBookings() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await _bookingsRef
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('date')
          .orderBy('timeSlot')
          .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ BookingService Error: $e');
      rethrow;
    }
  }

  /// Get upcoming bookings
  Future<List<Booking>> getUpcomingBookings() async {
    final allBookings = await getUserBookings();
    return allBookings.where((booking) => booking.isUpcoming).toList();
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        // 1. Get booking details
        final bookingRef = _bookingsRef.doc(bookingId);
        final bookingDoc = await transaction.get(bookingRef);

        if (!bookingDoc.exists) {
          throw Exception('Booking not found');
        }

        final booking = Booking.fromMap(
          bookingDoc.data() as Map<String, dynamic>,
        );

        // 2. Check if user owns this booking
        if (booking.userId != _currentUserId) {
          throw Exception('Unauthorized to cancel this booking');
        }

        // 3. Check if booking can be cancelled (more than 1 hour before)
        if (!booking.canCancel) {
          throw Exception(
            'Cannot cancel booking less than 1 hour before appointment',
          );
        }

        // 4. Get availability data (READ - must come before writes)
        final availabilityRef = _shopsRef
            .doc(booking.shopId)
            .collection('availability')
            .doc(booking.date);

        final availabilityDoc = await transaction.get(availabilityRef);

        // 5. Now do all WRITES
        // Update booking status
        transaction.update(bookingRef, {
          'status': BookingStatus.cancelled.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Free up time slots (if availability exists)
        if (availabilityDoc.exists) {
          final availability = ShopAvailability.fromMap(
            availabilityDoc.data()!,
            booking.shopId,
            booking.date,
          );

          final requiredSlots = ServiceTypes.generateTimeSlots(
            booking.timeSlot.split('-')[0],
            booking.totalDuration,
          );

          final updatedTimeSlots = availability.timeSlots.map(
            (key, value) => MapEntry(key, value.toMap()),
          );
          for (String slot in requiredSlots) {
            updatedTimeSlots[slot] = {
              'isAvailable': true,
              'bookingId': null,
              'serviceTypes': null,
            };
          }

          transaction.update(availabilityRef, {
            'timeSlots': updatedTimeSlots,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }

        return true;
      });
    } catch (e) {
      print('❌ BookingService Error: $e');
      rethrow;
    }
  }

  /// Get shop availability for a specific date
  Future<ShopAvailability?> getShopAvailability(
    String shopId,
    String date,
  ) async {
    try {
      final doc = await _shopsRef
          .doc(shopId)
          .collection('availability')
          .doc(date)
          .get();

      if (!doc.exists) {
        // Initialize availability if it doesn't exist
        await _initializeShopAvailability(shopId, date);
        final newDoc = await _shopsRef
            .doc(shopId)
            .collection('availability')
            .doc(date)
            .get();

        if (!newDoc.exists) return null;
        return ShopAvailability.fromMap(newDoc.data()!, shopId, date);
      }

      return ShopAvailability.fromMap(doc.data()!, shopId, date);
    } catch (e) {
      print('❌ BookingService Error: $e');
      rethrow;
    }
  }

  /// Stream shop availability for real-time updates
  Stream<ShopAvailability?> getShopAvailabilityStream(
    String shopId,
    String date,
  ) {
    return _shopsRef
        .doc(shopId)
        .collection('availability')
        .doc(date)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return ShopAvailability.fromMap(doc.data()!, shopId, date);
        });
  }

  /// Initialize shop availability for a date
  Future<void> _initializeShopAvailability(String shopId, String date) async {
    final allSlots = ServiceTypes.generateAllTimeSlots();
    final timeSlots = <String, dynamic>{};

    print('🔍 Initializing availability for shop $shopId on $date');
    print('🔍 Generated ${allSlots.length} time slots: $allSlots');

    for (String slot in allSlots) {
      timeSlots[slot] = {
        'isAvailable': true,
        'bookingId': null,
        'serviceTypes': null,
      };
    }

    await _shopsRef.doc(shopId).collection('availability').doc(date).set({
      'timeSlots': timeSlots,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    print('✅ Shop availability initialized successfully');
  }

  /// Get available time slots for a shop and date
  Future<List<TimeSlot>> getAvailableTimeSlots(
    String shopId,
    String date,
  ) async {
    final availability = await getShopAvailability(shopId, date);
    return availability?.availableSlots ?? [];
  }

  /// Check if a time range is available
  Future<bool> isTimeRangeAvailable({
    required String shopId,
    required String date,
    required String startTime,
    required int duration,
  }) async {
    final availability = await getShopAvailability(shopId, date);
    if (availability == null) return false;

    return availability.isTimeRangeAvailable(startTime, duration);
  }

  /// Update booking status (for shop use)
  Future<bool> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      await _bookingsRef.doc(bookingId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ BookingService Error: $e');
      return false;
    }
  }

  /// Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingsRef.doc(bookingId).get();
      if (!doc.exists) return null;
      return Booking.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ BookingService Error: $e');
      return null;
    }
  }

  /// Get bookings for a specific shop (for shop management)
  Future<List<Booking>> getShopBookings(String shopId) async {
    try {
      final querySnapshot = await _bookingsRef
          .where('shopId', isEqualTo: shopId)
          .orderBy('date')
          .orderBy('timeSlot')
          .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ BookingService Error: $e');
      rethrow;
    }
  }

  /// Update booking statuses automatically (mark past appointments as completed)
  Future<void> updateBookingStatuses() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get all confirmed bookings that should be completed
      final querySnapshot = await _bookingsRef
          .where('status', isEqualTo: 'confirmed')
          .get();

      final batch = _firestore.batch();
      int updateCount = 0;

      for (final doc in querySnapshot.docs) {
        final booking = Booking.fromMap(doc.data() as Map<String, dynamic>);
        final bookingDate = DateTime.parse(booking.date);

        // Check if booking is in the past
        if (bookingDate.isBefore(today)) {
          // Mark as completed
          batch.update(doc.reference, {
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          updateCount++;
        } else if (bookingDate.isAtSameMomentAs(today)) {
          // Check if time slot has passed
          final timeParts = booking.timeSlot.split('-')[0].split(':');
          final bookingTime = DateTime(
            bookingDate.year,
            bookingDate.month,
            bookingDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          if (bookingTime.isBefore(now)) {
            batch.update(doc.reference, {
              'status': 'completed',
              'updatedAt': FieldValue.serverTimestamp(),
            });
            updateCount++;
          }
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        print('✅ Updated $updateCount booking statuses to completed');
      }
    } catch (e) {
      print('❌ Error updating booking statuses: $e');
    }
  }

  /// Get available time slots for a shop and date with proper filtering
  Future<List<String>> getAvailableTimeSlotsForBooking(
    String shopId,
    String date,
  ) async {
    try {
      // First update any past booking statuses
      await updateBookingStatuses();

      final availability = await getShopAvailability(shopId, date);
      if (availability == null) return [];

      final bookingDate = DateTime.parse(date);
      final availableSlots = <String>[];

      for (final slot in availability.availableSlots) {
        // Check if slot is not in the past
        if (!ServiceTypes.isTimeSlotInPast(slot.time, bookingDate)) {
          availableSlots.add(slot.time);
        }
      }

      // Sort chronologically
      availableSlots.sort((a, b) {
        final aStart = a.split('-')[0];
        final bStart = b.split('-')[0];
        return _timeToMinutes(aStart).compareTo(_timeToMinutes(bStart));
      });

      return availableSlots;
    } catch (e) {
      print('❌ Error getting available time slots: $e');
      return [];
    }
  }

  // Helper method to convert time string to minutes
  int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
    } catch (e) {
      print('Error parsing time to minutes: $e');
    }
    return 0;
  }
}
