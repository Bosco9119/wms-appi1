import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/models/payment_model.dart';
import '../../shared/models/billing_item_model.dart';
import '../../shared/models/booking_model.dart';

class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _invoicesCollection = 'invoices';
  static const String _paymentsCollection = 'payments';

  /// Generate invoice number
  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = (now.millisecondsSinceEpoch % 10000).toString().padLeft(
      4,
      '0',
    );
    return 'INV-$year$month$day-$random';
  }

  /// Create invoice from booking
  Future<Invoice?> createInvoiceFromBooking(
    Booking booking, {
    double taxRate = 0.06, // 6% GST
    String? notes,
    String? terms,
  }) async {
    try {
      print('🧾 Creating invoice from booking: ${booking.id}');
      print('👤 Booking customer data:');
      print('   👤 Customer name: ${booking.customerName}');
      print('   📱 Customer phone: ${booking.customerPhone}');
      print('   📧 Customer email: ${booking.customerEmail}');
      print('   🆔 Customer ID: ${booking.userId}');

      // Generate billing items from booking services
      final List<BillingItem> items = [];
      double subtotal = 0.0;

      for (final service in booking.serviceTypes) {
        final item = BillingItem(
          id: '${booking.id}_${service}',
          name: service,
          description: 'Service: $service',
          quantity: 1.0,
          unitPrice: _getServicePrice(service),
          totalPrice: _getServicePrice(service),
          serviceType: service,
          category: 'Service',
        );
        items.add(item);
        subtotal += item.totalPrice;
      }

      // Calculate amounts
      final taxAmount = subtotal * taxRate;
      final totalAmount = subtotal + taxAmount;

      // Create invoice
      final invoice = Invoice(
        id: _firestore.collection(_invoicesCollection).doc().id,
        invoiceNumber: _generateInvoiceNumber(),
        customerId: booking.userId,
        customerName: booking.customerName,
        customerEmail: booking.customerEmail,
        customerPhone: booking.customerPhone,
        shopId: booking.shopId,
        shopName: booking.shopName,
        bookingId: booking.id,
        status: InvoiceStatus.draft,
        items: items,
        subtotal: subtotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        discountAmount: 0.0,
        totalAmount: totalAmount,
        paidAmount: 0.0,
        balanceAmount: totalAmount,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        notes: notes,
        terms: terms ?? 'Payment due within 30 days',
        payments: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📄 Invoice object created:');
      print('   🆔 Invoice ID: ${invoice.id}');
      print('   📋 Invoice Number: ${invoice.invoiceNumber}');
      print('   👤 Customer name: ${invoice.customerName}');
      print('   📱 Customer phone: ${invoice.customerPhone}');
      print('   📧 Customer email: ${invoice.customerEmail}');
      print('   💰 Total amount: RM ${invoice.totalAmount.toStringAsFixed(2)}');

      // Save to Firestore
      await _firestore
          .collection(_invoicesCollection)
          .doc(invoice.id)
          .set(invoice.toJson());

      print('✅ Invoice created: ${invoice.invoiceNumber}');
      print('   📄 Invoice ID: ${invoice.id}');
      print('   👤 Customer ID: ${invoice.customerId}');
      print('   💰 Total Amount: RM ${invoice.totalAmount.toStringAsFixed(2)}');
      print('   📅 Created: ${invoice.createdAt}');

      return invoice;
    } catch (e) {
      print('❌ Error creating invoice: $e');
      return null;
    }
  }

  /// Get service price (mock implementation - should be from service catalog)
  double _getServicePrice(String serviceType) {
    // Mock pricing - in real app, this should come from a service catalog
    switch (serviceType.toLowerCase()) {
      case 'engine repair':
        return 150.0;
      case 'transmission service':
        return 200.0;
      case 'suspension work':
        return 120.0;
      case 'brake service':
        return 80.0;
      case 'oil change':
        return 50.0;
      case 'tire rotation':
        return 30.0;
      case 'battery replacement':
        return 100.0;
      case 'air filter replacement':
        return 25.0;
      default:
        return 75.0; // Default price
    }
  }

  /// Get invoices for a customer
  Future<List<Invoice>> getCustomerInvoices(String customerId) async {
    try {
      // First try with the composite index query
      try {
        final querySnapshot = await _firestore
            .collection(_invoicesCollection)
            .where('customerId', isEqualTo: customerId)
            .orderBy('createdAt', descending: true)
            .get();

        return querySnapshot.docs
            .map((doc) => Invoice.fromJson(doc.data()))
            .toList();
      } catch (e) {
        print('⚠️ Composite index query failed, trying simple query: $e');

        // Fallback to simple query without orderBy
        final querySnapshot = await _firestore
            .collection(_invoicesCollection)
            .where('customerId', isEqualTo: customerId)
            .get();

        final invoices = querySnapshot.docs
            .map((doc) => Invoice.fromJson(doc.data()))
            .toList();

        // Sort manually
        invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return invoices;
      }
    } catch (e) {
      print('❌ Error fetching customer invoices: $e');
      return [];
    }
  }

  /// Get invoice by ID
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    try {
      final doc = await _firestore
          .collection(_invoicesCollection)
          .doc(invoiceId)
          .get();

      if (doc.exists) {
        return Invoice.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching invoice: $e');
      return null;
    }
  }

  /// Update invoice status
  Future<bool> updateInvoiceStatus(
    String invoiceId,
    InvoiceStatus status,
  ) async {
    try {
      await _firestore.collection(_invoicesCollection).doc(invoiceId).update({
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('❌ Error updating invoice status: $e');
      return false;
    }
  }

  /// Process payment
  Future<Payment?> processPayment({
    required String invoiceId,
    required PaymentMethod method,
    required double amount,
    String? transactionId,
    String? reference,
    String? notes,
  }) async {
    try {
      print('💳 Processing payment for invoice: $invoiceId');

      // Create payment record
      final payment = Payment(
        id: _firestore.collection(_paymentsCollection).doc().id,
        invoiceId: invoiceId,
        method: method,
        status: PaymentStatus.completed,
        amount: amount,
        transactionId: transactionId,
        reference: reference,
        notes: notes,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      // Save payment
      await _firestore
          .collection(_paymentsCollection)
          .doc(payment.id)
          .set(payment.toJson());

      // Update invoice
      await _updateInvoicePayment(invoiceId, amount);

      print('✅ Payment processed: ${payment.id}');
      return payment;
    } catch (e) {
      print('❌ Error processing payment: $e');
      return null;
    }
  }

  /// Update invoice payment amounts
  Future<void> _updateInvoicePayment(
    String invoiceId,
    double paymentAmount,
  ) async {
    try {
      final invoiceDoc = await _firestore
          .collection(_invoicesCollection)
          .doc(invoiceId)
          .get();

      if (invoiceDoc.exists) {
        final invoice = Invoice.fromJson(invoiceDoc.data()!);
        final newPaidAmount = invoice.paidAmount + paymentAmount;
        final newBalanceAmount = invoice.totalAmount - newPaidAmount;
        final newStatus = newBalanceAmount <= 0
            ? InvoiceStatus.paid
            : InvoiceStatus.sent;

        await _firestore.collection(_invoicesCollection).doc(invoiceId).update({
          'paidAmount': newPaidAmount,
          'balanceAmount': newBalanceAmount,
          'status': newStatus.name,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('❌ Error updating invoice payment: $e');
    }
  }

  /// Get payments for an invoice
  Future<List<Payment>> getInvoicePayments(String invoiceId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_paymentsCollection)
          .where('invoiceId', isEqualTo: invoiceId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Payment.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('❌ Error fetching invoice payments: $e');
      return [];
    }
  }

  /// Get billing statistics for a customer
  Future<Map<String, dynamic>> getBillingStatistics(String customerId) async {
    try {
      final invoices = await getCustomerInvoices(customerId);

      double totalAmount = 0.0;
      double paidAmount = 0.0;
      double overdueAmount = 0.0;
      int totalInvoices = invoices.length;
      int paidInvoices = 0;
      int overdueInvoices = 0;

      for (final invoice in invoices) {
        totalAmount += invoice.totalAmount;
        paidAmount += invoice.paidAmount;

        if (invoice.isPaid) {
          paidInvoices++;
        } else if (invoice.isOverdue) {
          overdueInvoices++;
          overdueAmount += invoice.balanceAmount;
        }
      }

      return {
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'overdueAmount': overdueAmount,
        'totalInvoices': totalInvoices,
        'paidInvoices': paidInvoices,
        'overdueInvoices': overdueInvoices,
        'outstandingAmount': totalAmount - paidAmount,
      };
    } catch (e) {
      print('❌ Error fetching billing statistics: $e');
      return {};
    }
  }

  /// Send invoice (update status to sent)
  Future<bool> sendInvoice(String invoiceId) async {
    return await updateInvoiceStatus(invoiceId, InvoiceStatus.sent);
  }

  /// Mark invoice as overdue
  Future<bool> markInvoiceOverdue(String invoiceId) async {
    return await updateInvoiceStatus(invoiceId, InvoiceStatus.overdue);
  }

  /// Cancel invoice
  Future<bool> cancelInvoice(String invoiceId) async {
    return await updateInvoiceStatus(invoiceId, InvoiceStatus.cancelled);
  }

  /// Refund invoice
  Future<bool> refundInvoice(String invoiceId) async {
    return await updateInvoiceStatus(invoiceId, InvoiceStatus.refunded);
  }
}
