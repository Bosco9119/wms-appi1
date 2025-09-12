import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/service_progress_model.dart';
import '../../shared/models/booking_model.dart';

class ServiceProgressService {
  static final ServiceProgressService _instance =
      ServiceProgressService._internal();
  factory ServiceProgressService() => _instance;
  ServiceProgressService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create service progress from booking
  Future<ServiceProgress?> createServiceProgressFromBooking(
    Booking booking,
  ) async {
    try {
      final serviceProgressId = 'sp_${booking.id}';

      // Calculate estimated completion time based on service types
      final estimatedDuration = _calculateEstimatedDuration(
        booking.serviceTypes,
      );
      final estimatedCompletionTime = DateTime.now().add(
        Duration(minutes: estimatedDuration),
      );

      final serviceProgress = ServiceProgress(
        id: serviceProgressId,
        bookingId: booking.id,
        shopId: booking.shopId,
        userId: booking.userId,
        vehicleId: booking.vehicleId ?? 'unknown',
        serviceTypes: booking.serviceTypes,
        currentStatus: ServiceStatus.scheduled,
        statusHistory: [
          ServiceStatusUpdate(
            status: ServiceStatus.scheduled,
            notes: 'Service appointment scheduled',
            timestamp: DateTime.now(),
            updatedBy: 'System',
          ),
        ],
        currentNotes:
            'Service scheduled for ${booking.date} at ${booking.timeSlot}',
        estimatedCompletionTime: estimatedCompletionTime.toIso8601String(),
        actualStartTime: null,
        actualEndTime: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        shopName: booking.shopName,
        customerName: booking.customerName,
        customerPhone: booking.customerPhone,
        vehicleModel: 'Vehicle Model', // This should come from vehicle data
        vehiclePlate: 'ABC-1234', // This should come from vehicle data
      );

      await _firestore
          .collection('service_progress')
          .doc(serviceProgressId)
          .set(serviceProgress.toMap());

      print(
        '✅ ServiceProgressService: Service progress created for booking ${booking.id}',
      );
      return serviceProgress;
    } catch (e) {
      print('❌ ServiceProgressService: Error creating service progress: $e');
      return null;
    }
  }

  /// Update service status
  Future<bool> updateServiceStatus({
    required String serviceProgressId,
    required ServiceStatus newStatus,
    String? notes,
    String updatedBy = 'System',
  }) async {
    try {
      final docRef = _firestore
          .collection('service_progress')
          .doc(serviceProgressId);
      final doc = await docRef.get();

      if (!doc.exists) {
        print(
          '❌ ServiceProgressService: Service progress not found: $serviceProgressId',
        );
        return false;
      }

      final currentData = doc.data()!;
      final currentStatusHistory =
          (currentData['statusHistory'] as List<dynamic>)
              .map(
                (item) =>
                    ServiceStatusUpdate.fromMap(item as Map<String, dynamic>),
              )
              .toList();

      // Add new status update
      final newStatusUpdate = ServiceStatusUpdate(
        status: newStatus,
        notes: notes,
        timestamp: DateTime.now(),
        updatedBy: updatedBy,
      );

      currentStatusHistory.add(newStatusUpdate);

      // Update the document
      await docRef.update({
        'currentStatus': newStatus.name,
        'statusHistory': currentStatusHistory
            .map((update) => update.toMap())
            .toList(),
        'currentNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
        'actualStartTime':
            newStatus == ServiceStatus.inInspection &&
                currentData['actualStartTime'] == null
            ? FieldValue.serverTimestamp()
            : currentData['actualStartTime'],
        'actualEndTime': newStatus == ServiceStatus.completed
            ? FieldValue.serverTimestamp()
            : currentData['actualEndTime'],
      });

      print(
        '✅ ServiceProgressService: Status updated to ${newStatus.name} for $serviceProgressId',
      );
      return true;
    } catch (e) {
      print('❌ ServiceProgressService: Error updating service status: $e');
      return false;
    }
  }

  /// Get service progress by ID
  Future<ServiceProgress?> getServiceProgressById(
    String serviceProgressId,
  ) async {
    try {
      final doc = await _firestore
          .collection('service_progress')
          .doc(serviceProgressId)
          .get();

      if (!doc.exists) return null;

      return ServiceProgress.fromMap(doc.data()!);
    } catch (e) {
      print('❌ ServiceProgressService: Error getting service progress: $e');
      return null;
    }
  }

  /// Get service progress by booking ID
  Future<ServiceProgress?> getServiceProgressByBookingId(
    String bookingId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('service_progress')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return ServiceProgress.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      print(
        '❌ ServiceProgressService: Error getting service progress by booking ID: $e',
      );
      return null;
    }
  }

  /// Get all service progress for a user
  Future<List<ServiceProgress>> getUserServiceProgress(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('service_progress')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceProgress.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print(
        '❌ ServiceProgressService: Error getting user service progress: $e',
      );
      return [];
    }
  }

  /// Get active service progress for a user
  Future<List<ServiceProgress>> getActiveUserServiceProgress(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('service_progress')
          .where('userId', isEqualTo: userId)
          .where(
            'currentStatus',
            whereIn: [
              ServiceStatus.scheduled.name,
              ServiceStatus.inInspection.name,
              ServiceStatus.partsAwaiting.name,
              ServiceStatus.inRepair.name,
              ServiceStatus.qualityCheck.name,
              ServiceStatus.readyForCollection.name,
            ],
          )
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceProgress.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print(
        '❌ ServiceProgressService: Error getting active user service progress: $e',
      );
      return [];
    }
  }

  /// Get all service progress for a shop
  Future<List<ServiceProgress>> getShopServiceProgress(String shopId) async {
    try {
      final querySnapshot = await _firestore
          .collection('service_progress')
          .where('shopId', isEqualTo: shopId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceProgress.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print(
        '❌ ServiceProgressService: Error getting shop service progress: $e',
      );
      return [];
    }
  }

  /// Get active service progress for a shop
  Future<List<ServiceProgress>> getActiveShopServiceProgress(
    String shopId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('service_progress')
          .where('shopId', isEqualTo: shopId)
          .where(
            'currentStatus',
            whereIn: [
              ServiceStatus.scheduled.name,
              ServiceStatus.inInspection.name,
              ServiceStatus.partsAwaiting.name,
              ServiceStatus.inRepair.name,
              ServiceStatus.qualityCheck.name,
              ServiceStatus.readyForCollection.name,
            ],
          )
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceProgress.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print(
        '❌ ServiceProgressService: Error getting active shop service progress: $e',
      );
      return [];
    }
  }

  /// Stream service progress for real-time updates
  Stream<ServiceProgress?> streamServiceProgress(String serviceProgressId) {
    return _firestore
        .collection('service_progress')
        .doc(serviceProgressId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return ServiceProgress.fromMap(doc.data()!);
        });
  }

  /// Stream user service progress for real-time updates
  Stream<List<ServiceProgress>> streamUserServiceProgress(String userId) {
    return _firestore
        .collection('service_progress')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ServiceProgress.fromMap(doc.data()))
              .toList();
        });
  }

  /// Stream active user service progress for real-time updates
  Stream<List<ServiceProgress>> streamActiveUserServiceProgress(String userId) {
    return _firestore
        .collection('service_progress')
        .where('userId', isEqualTo: userId)
        .where(
          'currentStatus',
          whereIn: [
            ServiceStatus.scheduled.name,
            ServiceStatus.inInspection.name,
            ServiceStatus.partsAwaiting.name,
            ServiceStatus.inRepair.name,
            ServiceStatus.qualityCheck.name,
            ServiceStatus.readyForCollection.name,
          ],
        )
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ServiceProgress.fromMap(doc.data()))
              .toList();
        });
  }

  /// Delete service progress
  Future<bool> deleteServiceProgress(String serviceProgressId) async {
    try {
      await _firestore
          .collection('service_progress')
          .doc(serviceProgressId)
          .delete();

      print(
        '✅ ServiceProgressService: Service progress deleted: $serviceProgressId',
      );
      return true;
    } catch (e) {
      print('❌ ServiceProgressService: Error deleting service progress: $e');
      return false;
    }
  }

  /// Calculate estimated duration based on service types
  int _calculateEstimatedDuration(List<String> serviceTypes) {
    // Base duration mapping for different service types
    final serviceDurations = {
      'Oil Change': 30,
      'Engine Service': 120,
      'Transmission': 180,
      'Brake Service': 90,
      'Tire Service': 60,
      'Battery Service': 45,
      'AC Service': 90,
      'Electrical Service': 120,
      'Suspension Service': 150,
      'Exhaust Service': 90,
    };

    int totalDuration = 0;
    for (final serviceType in serviceTypes) {
      totalDuration +=
          serviceDurations[serviceType] ?? 60; // Default 60 minutes
    }

    // Add buffer time (20% of total duration)
    return (totalDuration * 1.2).round();
  }

  /// Get service progress statistics
  Future<Map<String, int>> getServiceProgressStatistics(String shopId) async {
    try {
      final querySnapshot = await _firestore
          .collection('service_progress')
          .where('shopId', isEqualTo: shopId)
          .get();

      final stats = <String, int>{};
      for (final status in ServiceStatus.values) {
        stats[status.name] = 0;
      }

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['currentStatus'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ ServiceProgressService: Error getting statistics: $e');
      return {};
    }
  }

  /// Auto-update status based on time (for testing/demo purposes)
  Future<void> autoUpdateStatuses() async {
    try {
      print('🔄 ServiceProgressService: Auto-updating service statuses...');

      final querySnapshot = await _firestore
          .collection('service_progress')
          .where(
            'currentStatus',
            whereIn: [
              ServiceStatus.scheduled.name,
              ServiceStatus.inInspection.name,
              ServiceStatus.partsAwaiting.name,
              ServiceStatus.inRepair.name,
              ServiceStatus.qualityCheck.name,
            ],
          )
          .get();

      for (final doc in querySnapshot.docs) {
        final serviceProgress = ServiceProgress.fromMap(doc.data());
        final now = DateTime.now();
        final createdAt = serviceProgress.createdAt;
        final hoursSinceCreation = now.difference(createdAt).inHours;

        ServiceStatus? newStatus;
        String? notes;

        // Auto-progress based on time (for demo purposes)
        switch (serviceProgress.currentStatus) {
          case ServiceStatus.scheduled:
            if (hoursSinceCreation >= 1) {
              newStatus = ServiceStatus.inInspection;
              notes = 'Auto-updated: Service started';
            }
            break;
          case ServiceStatus.inInspection:
            if (hoursSinceCreation >= 2) {
              newStatus = ServiceStatus.partsAwaiting;
              notes = 'Auto-updated: Inspection completed, waiting for parts';
            }
            break;
          case ServiceStatus.partsAwaiting:
            if (hoursSinceCreation >= 4) {
              newStatus = ServiceStatus.inRepair;
              notes = 'Auto-updated: Parts arrived, repair started';
            }
            break;
          case ServiceStatus.inRepair:
            if (hoursSinceCreation >= 6) {
              newStatus = ServiceStatus.qualityCheck;
              notes = 'Auto-updated: Repair completed, quality check started';
            }
            break;
          case ServiceStatus.qualityCheck:
            if (hoursSinceCreation >= 7) {
              newStatus = ServiceStatus.readyForCollection;
              notes =
                  'Auto-updated: Quality check completed, ready for collection';
            }
            break;
          default:
            break;
        }

        if (newStatus != null) {
          await updateServiceStatus(
            serviceProgressId: serviceProgress.id,
            newStatus: newStatus,
            notes: notes,
            updatedBy: 'Auto-System',
          );
        }
      }

      print('✅ ServiceProgressService: Auto-update completed');
    } catch (e) {
      print('❌ ServiceProgressService: Error in auto-update: $e');
    }
  }
}
