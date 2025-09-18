import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/payment_model.dart';
import '../../../core/constants/payment_constants.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PaymentModel> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get payments from the payments collection (Billplz payments)
      final query = await _firestore
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .get();

      final payments = query.docs
          .where((doc) {
            final data = doc.data();
            
            // Filter: Only include Billplz payments (have billId and billUrl)
            // Exclude legacy billing payments (have method field)
            // Only include completed payments
            final hasBillId = data['billId'] != null && data['billId'].toString().isNotEmpty;
            final hasMethod = data['method'] != null;
            final isCompleted = data['status'] == 'completed' || data['status'] == 'paid';
            
            return hasBillId && !hasMethod && isCompleted; // Only completed Billplz payments
          })
          .map((doc) {
            final data = doc.data();
            return PaymentModel(
              billId: data['billId'] ?? '',
              orderId: data['orderId'] ?? '',
              customerName: data['customerName'] ?? '',
              customerEmail: data['customerEmail'] ?? '',
              customerPhone: data['customerPhone'] ?? '',
              amount: (data['amount'] ?? 0.0).toDouble(),
              description: data['description'] ?? '',
              status: _parsePaymentStatus(data['status'] ?? 'pending'),
              billUrl: data['billUrl'] ?? '',
              createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
              updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
            );
          })
          .toList();

      setState(() {
        _payments = payments;
        _isLoading = false;
      });
      
      print('📄 Total completed payments loaded: ${payments.length}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load payment history: $e';
        _isLoading = false;
      });
    }
  }

  PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        print('Error parsing date string: $e');
        return null;
      }
    }
    
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Payments'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPaymentHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPaymentHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No completed payments found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed payment history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payments.length,
        itemBuilder: (context, index) {
          final payment = _payments[index];
          return _buildPaymentCard(payment);
        },
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              payment.orderId.isNotEmpty ? payment.orderId : 'Payment ${payment.billId}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              payment.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Customer: ${payment.customerName}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${_formatDate(payment.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ${PaymentConstants.currencySymbol}${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCF2049),
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
