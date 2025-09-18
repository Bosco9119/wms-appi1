import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../constants/payment_constants.dart';
import '../../shared/models/payment_model.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Create a new payment bill
  Future<PaymentResponse> createBill(CreatePaymentRequest request) async {
    try {
      // Direct Billplz API call (temporary solution)
      final billplzData = {
        'collection_id': 'xsu0hjux',
        'email': request.customerEmail,
        'mobile': request.customerPhone ?? '',
        'name': request.customerName,
        'amount': (request.amount * 100).round(), // Convert to cents
        'description': request.description,
        'callback_url': 'https://us-central1-wms-appi1.cloudfunctions.net/paymentCallback',
        'redirect_url': 'https://httpbin.org/status/200?payment=success',
        'due_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'reference_1_label': 'Order ID',
        'reference_1': request.orderId ?? '',
        'reference_2_label': 'Customer',
        'reference_2': request.customerName,
      };

      final response = await http.post(
        Uri.parse('https://www.billplz-sandbox.com/api/v3/bills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('1149106e-4ef2-474b-8eea-eadbf21818be:'))}',
        },
        body: jsonEncode(billplzData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Save to Firestore directly
        await _firestore.collection('payments').doc(data['id']).set({
          'billId': data['id'],
          'orderId': request.orderId ?? '',
          'customerName': request.customerName,
          'customerEmail': request.customerEmail,
          'customerPhone': request.customerPhone ?? '',
          'amount': request.amount,
          'description': request.description,
          'status': 'pending',
          'billUrl': data['url'],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        return PaymentResponse(
          success: true,
          billId: data['id'],
          billUrl: data['url'],
          message: 'Bill created successfully',
        );
      } else {
        throw Exception('Failed to create bill: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating payment bill: $e');
    }
  }

  /// Get payment status by bill ID
  Future<PaymentResponse> getPaymentStatus(String billId) async {
    try {
      final callable = _functions.httpsCallable('getPaymentStatus');
      final result = await callable.call({'billId': billId});

      if (result.data != null) {
        return PaymentResponse.fromJson(result.data);
      } else {
        throw Exception('Failed to get payment status: No data returned');
      }
    } catch (e) {
      throw Exception('Error getting payment status: $e');
    }
  }

  /// Get customer payment history
  Future<PaymentResponse> getCustomerPayments(String customerEmail, {int limit = 10}) async {
    try {
      final callable = _functions.httpsCallable('getCustomerPayments');
      final result = await callable.call({
        'customerEmail': customerEmail,
        'limit': limit,
      });

      if (result.data != null) {
        return PaymentResponse.fromJson(result.data);
      } else {
        throw Exception('Failed to get customer payments: No data returned');
      }
    } catch (e) {
      throw Exception('Error getting customer payments: $e');
    }
  }

  /// Listen to payment status changes in real-time
  Stream<PaymentModel?> listenToPaymentStatus(String billId) {
    return _firestore
        .collection('payments')
        .doc(billId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return PaymentModel.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  /// Listen to customer payments in real-time
  Stream<List<PaymentModel>> listenToCustomerPayments(String customerEmail, {int limit = 10}) {
    return _firestore
        .collection('payments')
        .where('customerEmail', isEqualTo: customerEmail)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Validate payment amount
  bool validateAmount(double amount) {
    return amount >= PaymentConstants.minimumAmount && 
           amount <= PaymentConstants.maximumAmount;
  }

  /// Format amount for display
  String formatAmount(double amount) {
    return '${PaymentConstants.currencySymbol} ${amount.toStringAsFixed(2)}';
  }

  /// Get payment status color
  int getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return PaymentConstants.paymentSuccessColor;
      case PaymentStatus.pending:
        return PaymentConstants.paymentPendingColor;
      case PaymentStatus.failed:
        return PaymentConstants.paymentFailedColor;
      case PaymentStatus.cancelled:
        return PaymentConstants.paymentCancelledColor;
    }
  }

  /// Get payment status icon
  String getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return '✓';
      case PaymentStatus.pending:
        return '⏳';
      case PaymentStatus.failed:
        return '✗';
      case PaymentStatus.cancelled:
        return '⊘';
    }
  }

  /// Create payment description based on service type
  String createPaymentDescription(String serviceType, String? additionalInfo) {
    String baseDescription;
    
    switch (serviceType.toLowerCase()) {
      case 'repair':
        baseDescription = PaymentConstants.repairPaymentDescription;
        break;
      case 'maintenance':
        baseDescription = PaymentConstants.maintenancePaymentDescription;
        break;
      case 'inspection':
        baseDescription = PaymentConstants.inspectionPaymentDescription;
        break;
      default:
        baseDescription = PaymentConstants.servicePaymentDescription;
    }

    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      return '$baseDescription - $additionalInfo';
    }
    
    return baseDescription;
  }

  /// Check if payment is completed
  bool isPaymentCompleted(PaymentStatus status) {
    return status == PaymentStatus.completed;
  }

  /// Check if payment is pending
  bool isPaymentPending(PaymentStatus status) {
    return status == PaymentStatus.pending;
  }

  /// Check if payment failed
  bool isPaymentFailed(PaymentStatus status) {
    return status == PaymentStatus.failed || status == PaymentStatus.cancelled;
  }

  /// Update payment status
  Future<PaymentResponse> updatePaymentStatus(String billId, PaymentStatus newStatus) async {
    try {
      await _firestore.collection('payments').doc(billId).update({
        'status': newStatus.value,
        'updatedAt': Timestamp.now(),
      });

      return PaymentResponse(
        success: true,
        billId: billId,
        message: 'Payment status updated successfully',
      );
    } catch (e) {
      throw Exception('Error updating payment status: $e');
    }
  }

  /// Update payment amount
  Future<PaymentResponse> updatePaymentAmount(String billId, double newAmount) async {
    try {
      await _firestore.collection('payments').doc(billId).update({
        'amount': newAmount,
        'updatedAt': Timestamp.now(),
      });

      return PaymentResponse(
        success: true,
        billId: billId,
        message: 'Payment amount updated successfully',
      );
    } catch (e) {
      throw Exception('Error updating payment amount: $e');
    }
  }

  /// Update payment details
  Future<PaymentResponse> updatePaymentDetails(String billId, {
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (customerName != null) updateData['customerName'] = customerName;
      if (customerEmail != null) updateData['customerEmail'] = customerEmail;
      if (customerPhone != null) updateData['customerPhone'] = customerPhone;
      if (description != null) updateData['description'] = description;

      await _firestore.collection('payments').doc(billId).update(updateData);

      return PaymentResponse(
        success: true,
        billId: billId,
        message: 'Payment details updated successfully',
      );
    } catch (e) {
      throw Exception('Error updating payment details: $e');
    }
  }
}
