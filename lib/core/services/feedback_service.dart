import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/service_progress_model.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _feedbackRef => _firestore.collection('feedback');
  CollectionReference get _serviceProgressRef =>
      _firestore.collection('service_progress');

  String? get _currentUserId => _auth.currentUser?.uid;

  /// List completed services for current user, grouped by vehicle.
  Future<List<ServiceProgress>> getCompletedServicesForCurrentUser() async {
    if (_currentUserId == null) return [];
    try {
      final snapshot = await _serviceProgressRef
          .where('userId', isEqualTo: _currentUserId)
          .where('currentStatus', isEqualTo: ServiceStatus.completed.name)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((d) => ServiceProgress.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ FeedbackService: error fetching completed services: $e');
      return [];
    }
  }

  /// Check if feedback already exists for a bookingId.
  Future<bool> hasFeedbackForBooking(String bookingId) async {
    try {
      final q = await _feedbackRef
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      return q.docs.isNotEmpty;
    } catch (e) {
      print('❌ FeedbackService: error checking feedback existence: $e');
      return false;
    }
  }

  /// Submit feedback for a completed service.
  Future<bool> submitFeedback({
    required String bookingId,
    required String shopId,
    required int ratingOverall,
    required int serviceQuality,
    required int timeliness,
    required int communication,
    List<String>? imageUrls,
    String? comment,
    List<String>? tags,
    bool? allowContact,
    Map<String, dynamic>? questions,
  }) async {
    if (_currentUserId == null) return false;

    try {
      final exists = await hasFeedbackForBooking(bookingId);
      if (exists) {
        print('⚠️ FeedbackService: feedback already exists for $bookingId');
        return false;
      }

      final doc = _feedbackRef.doc();
      final now = DateTime.now().toIso8601String();
      final data = {
        'id': doc.id,
        'bookingId': bookingId,
        'customerId': _currentUserId,
        'shopId': shopId,
        'rating': ratingOverall,
        'serviceQuality': serviceQuality,
        'timeliness': timeliness,
        'communication': communication,
        'valueForMoney': 0, // Optional, set 0 when not used
        'comment': comment,
        'tags': tags ?? [],
        'allowContact': allowContact ?? false,
        'questions': questions ?? {},
        'createdAt': now,
        'updatedAt': now,
      };
      if (imageUrls != null && imageUrls.isNotEmpty) {
        data['images'] = imageUrls;
      }
      await doc.set(data);
      return true;
    } catch (e) {
      print('❌ FeedbackService: error submitting feedback: $e');
      return false;
    }
  }

  /// List feedback submitted by current user (most recent first)
  Future<List<Map<String, dynamic>>> getMyFeedback() async {
    if (_currentUserId == null) return [];
    try {
      final q = await _feedbackRef
          .where('customerId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();
      return q.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('❌ FeedbackService: error fetching my feedback: $e');
      return [];
    }
  }

  /// Get single feedback by id
  Future<Map<String, dynamic>?> getFeedbackById(String id) async {
    try {
      final doc = await _feedbackRef.doc(id).get();
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      print('❌ FeedbackService: error getFeedbackById: $e');
      return null;
    }
  }

  /// Get feedback by bookingId
  Future<Map<String, dynamic>?> getFeedbackByBookingId(String bookingId) async {
    if (_currentUserId == null) return null;
    
    try {
      final q = await _feedbackRef
          .where('bookingId', isEqualTo: bookingId)
          .where('customerId', isEqualTo: _currentUserId)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return null;
      return q.docs.first.data() as Map<String, dynamic>;
    } catch (e) {
      print('❌ FeedbackService: error getFeedbackByBookingId: $e');
      return null;
    }
  }

  /// Update existing feedback by bookingId
  Future<bool> updateFeedbackByBooking({
    required String bookingId,
    required int ratingOverall,
    required int serviceQuality,
    required int timeliness,
    required int communication,
    String? comment,
    List<String>? imageUrls,
    List<String>? tags,
    bool? allowContact,
    Map<String, dynamic>? questions,
  }) async {
    if (_currentUserId == null) return false;
    
    try {
      final q = await _feedbackRef
          .where('bookingId', isEqualTo: bookingId)
          .where('customerId', isEqualTo: _currentUserId)
          .limit(1)
          .get();
      if (q.docs.isEmpty) {
        print('⚠️ FeedbackService: No existing feedback found for $bookingId to update.');
        return false;
      }
      final id = q.docs.first.id;
      final Map<String, dynamic> update = {
        'rating': ratingOverall,
        'serviceQuality': serviceQuality,
        'timeliness': timeliness,
        'communication': communication,
        'comment': comment,
        if (tags != null) 'tags': tags,
        if (allowContact != null) 'allowContact': allowContact,
        if (questions != null) 'questions': questions,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (imageUrls != null) {
        // If caller provides an images list, set it; if empty, delete the field
        if (imageUrls.isEmpty) {
          update['images'] = FieldValue.delete();
        } else {
          update['images'] = imageUrls;
        }
      } else {
        // No images feature anymore: proactively delete the field on updates
        update['images'] = FieldValue.delete();
      }
      await _feedbackRef.doc(id).update(update);
      print('✅ FeedbackService: Feedback updated for $bookingId');
      return true;
    } catch (e) {
      print('❌ FeedbackService: error updateFeedbackByBooking: $e');
      return false;
    }
  }
}
