import 'package:flutter/material.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/constants/payment_constants.dart';
import '../../../shared/models/payment_model.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String customerEmail;

  const PaymentHistoryScreen({
    Key? key,
    required this.customerEmail,
  }) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  List<PaymentModel> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _paymentService.getCustomerPayments(widget.customerEmail);
      
      if (response.success && response.payments != null) {
        setState(() {
          _payments = response.payments!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load payments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading payments: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading payment history...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPayments,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No payment history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your payment history will appear here',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
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
      elevation: PaymentConstants.paymentCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PaymentConstants.paymentCardBorderRadius),
      ),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(PaymentConstants.paymentCardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      payment.description,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(_paymentService.getPaymentStatusColor(payment.status)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      payment.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _paymentService.formatAmount(payment.amount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    _formatDate(payment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (payment.orderId.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Order ID: ${payment.orderId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (payment.transactionId != null && payment.transactionId!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Transaction ID: ${payment.transactionId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDetails(PaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', payment.description),
              _buildDetailRow('Amount', _paymentService.formatAmount(payment.amount)),
              _buildDetailRow('Status', payment.status.displayName),
              _buildDetailRow('Customer', payment.customerName),
              _buildDetailRow('Email', payment.customerEmail),
              if (payment.customerPhone != null && payment.customerPhone!.isNotEmpty)
                _buildDetailRow('Phone', payment.customerPhone!),
              if (payment.orderId.isNotEmpty)
                _buildDetailRow('Order ID', payment.orderId),
              if (payment.transactionId != null && payment.transactionId!.isNotEmpty)
                _buildDetailRow('Transaction ID', payment.transactionId!),
              _buildDetailRow('Created', _formatDateTime(payment.createdAt)),
              _buildDetailRow('Updated', _formatDateTime(payment.updatedAt)),
              if (payment.paidAt != null)
                _buildDetailRow('Paid At', _formatDateTime(payment.paidAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
