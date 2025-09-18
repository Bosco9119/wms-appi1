import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/invoice_model.dart';
import '../../shared/models/billing_item_model.dart';
import '../../shared/models/booking_model.dart';
import '../constants/service_types.dart';

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

  /// Get service price - uses ServiceTypes for consistent pricing
  double _getServicePrice(String serviceType) {
    // First try to get the service from ServiceTypes
    final service = ServiceTypes.getByName(serviceType);
    if (service != null) {
      return service.baseCost;
    }
    
    // Fallback for legacy service names or unknown services
    switch (serviceType.toLowerCase()) {
      case 'engine repair':
        return 120.0; // Map to engine diagnostic
      case 'brake service':
        return 80.0; // Map to brake check
      case 'battery replacement':
        return 30.0; // Map to battery check
      case 'suspension work':
        return 120.0; // Map to engine diagnostic
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

  /// Process Billplz payment completion
  Future<bool> processBillplzPayment({
    required String invoiceId,
    required double amount,
    required String billplzBillId,
    String? notes,
  }) async {
    try {
      print('💳 Processing Billplz payment for invoice: $invoiceId');

      // Check if invoice exists and get current state
      final invoiceDoc = await _firestore
          .collection(_invoicesCollection)
          .doc(invoiceId)
          .get();

      if (!invoiceDoc.exists) {
        print('❌ Invoice not found: $invoiceId');
        return false;
      }

      final invoice = Invoice.fromJson(invoiceDoc.data()!);
      
      // Check if invoice is already fully paid
      if (invoice.isPaid) {
        print('⚠️ Invoice already fully paid: $invoiceId');
        return false;
      }

      // Check if payment amount exceeds balance
      if (amount > invoice.balanceAmount) {
        print('⚠️ Payment amount (RM ${amount.toStringAsFixed(2)}) exceeds balance (RM ${invoice.balanceAmount.toStringAsFixed(2)})');
        return false;
      }

      // Update invoice directly (Billplz payment record is already saved in PaymentService)
      await _updateInvoicePayment(invoiceId, amount);

      print('✅ Billplz payment processed for invoice: $invoiceId');
      return true;
    } catch (e) {
      print('❌ Error processing Billplz payment: $e');
      return false;
    }
  }

  /// Update invoice payment amounts
  Future<void> _updateInvoicePayment(
    String invoiceId,
    double paymentAmount,
  ) async {
    try {
      print('🔄 Updating invoice payment for: $invoiceId');
      print('   💰 Payment amount: RM ${paymentAmount.toStringAsFixed(2)}');
      
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

        print('   📊 Invoice details:');
        print('      💰 Total: RM ${invoice.totalAmount.toStringAsFixed(2)}');
        print('      💳 Current paid: RM ${invoice.paidAmount.toStringAsFixed(2)}');
        print('      💳 New paid: RM ${newPaidAmount.toStringAsFixed(2)}');
        print('      ⚖️ New balance: RM ${newBalanceAmount.toStringAsFixed(2)}');
        print('      📋 New status: ${newStatus.name}');

        await _firestore.collection(_invoicesCollection).doc(invoiceId).update({
          'paidAmount': newPaidAmount,
          'balanceAmount': newBalanceAmount,
          'status': newStatus.name,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        
        print('✅ Invoice updated successfully!');
      } else {
        print('❌ Invoice document not found: $invoiceId');
      }
    } catch (e) {
      print('❌ Error updating invoice payment: $e');
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

  /// Fix corrupted invoice data (for database cleanup)
  Future<bool> fixInvoiceData(String invoiceId) async {
    try {
      print('🔧 Fixing invoice data for: $invoiceId');
      
      final invoiceDoc = await _firestore
          .collection(_invoicesCollection)
          .doc(invoiceId)
          .get();

      if (!invoiceDoc.exists) {
        print('❌ Invoice not found: $invoiceId');
        return false;
      }

      final invoice = Invoice.fromJson(invoiceDoc.data()!);
      
      // Get all Billplz payments for this invoice from the payments collection
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('orderId', isEqualTo: invoice.invoiceNumber)
          .where('status', isEqualTo: 'completed')
          .get();
      
      final totalPaidAmount = paymentsQuery.docs.fold(0.0, (sum, doc) {
        final data = doc.data();
        return sum + (data['amount'] ?? 0.0).toDouble();
      });
      
      // Calculate correct balance
      final correctBalanceAmount = invoice.totalAmount - totalPaidAmount;
      final correctStatus = correctBalanceAmount <= 0 ? InvoiceStatus.paid : InvoiceStatus.sent;
      
      print('📊 Invoice correction:');
      print('   💰 Total: RM ${invoice.totalAmount.toStringAsFixed(2)}');
      print('   💳 Current paid: RM ${invoice.paidAmount.toStringAsFixed(2)}');
      print('   💳 Correct paid: RM ${totalPaidAmount.toStringAsFixed(2)}');
      print('   ⚖️ Current balance: RM ${invoice.balanceAmount.toStringAsFixed(2)}');
      print('   ⚖️ Correct balance: RM ${correctBalanceAmount.toStringAsFixed(2)}');
      print('   📋 Current status: ${invoice.status.name}');
      print('   📋 Correct status: ${correctStatus.name}');

      // Update invoice with correct data
      await _firestore.collection(_invoicesCollection).doc(invoiceId).update({
        'paidAmount': totalPaidAmount,
        'balanceAmount': correctBalanceAmount,
        'status': correctStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Invoice data fixed successfully!');
      return true;
    } catch (e) {
      print('❌ Error fixing invoice data: $e');
      return false;
    }
  }

  /// Fix all corrupted invoices for a customer
  Future<int> fixAllCustomerInvoices(String customerId) async {
    try {
      print('🔧 Fixing all invoices for customer: $customerId');
      
      final invoices = await getCustomerInvoices(customerId);
      int fixedCount = 0;
      
      for (final invoice in invoices) {
        if (await fixInvoiceData(invoice.id)) {
          fixedCount++;
        }
      }
      
      print('✅ Fixed $fixedCount out of ${invoices.length} invoices');
      return fixedCount;
    } catch (e) {
      print('❌ Error fixing customer invoices: $e');
      return 0;
    }
  }
}
