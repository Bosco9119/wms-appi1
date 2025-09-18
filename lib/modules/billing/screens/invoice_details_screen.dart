import 'package:flutter/material.dart';
import '../../../core/services/billing_service.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/models/billing_item_model.dart';
import '../../../shared/models/payment_model.dart' as payment_model;
import '../../../shared/providers/customer_provider.dart';
import '../../../modules/payment/screens/payment_screen.dart';
import 'package:provider/provider.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  final BillingService _billingService = BillingService();
  Invoice? _invoice;
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvoiceDetails();
  }

  Future<void> _loadInvoiceDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invoice = await _billingService.getInvoiceById(widget.invoiceId);
      if (invoice != null) {
        setState(() {
          _invoice = invoice;
          _payments = invoice.payments;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Invoice not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load invoice: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoiceDetails,
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

    if (_errorMessage != null || _invoice == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Invoice not found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInvoiceDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInvoiceHeader(),
          const SizedBox(height: 24),
          _buildCustomerInfo(),
          const SizedBox(height: 24),
          _buildItemsList(),
          const SizedBox(height: 24),
          _buildAmountsSummary(),
          const SizedBox(height: 24),
          _buildPaymentsSection(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _invoice!.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(_invoice!.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Issue Date: ${_formatDate(_invoice!.issueDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              'Due Date: ${_formatDate(_invoice!.dueDate)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill To',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _invoice!.customerName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              _invoice!.customerEmail,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (_invoice!.customerPhone != null)
              Text(
                _invoice!.customerPhone!,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            const SizedBox(height: 16),
            const Text(
              'Service Provider',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _invoice!.shopName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._invoice!.items.map((item) => _buildItemRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(BillingItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              'Qty: ${item.quantity.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'RM ${item.unitPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              'RM ${item.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCF2049),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAmountRow('Subtotal', _invoice!.subtotal),
            _buildAmountRow(
              'Tax (${(_invoice!.taxRate * 100).toStringAsFixed(0)}%)',
              _invoice!.taxAmount,
            ),
            if (_invoice!.discountAmount > 0)
              _buildAmountRow(
                'Discount',
                -_invoice!.discountAmount,
                isDiscount: true,
              ),
            const Divider(),
            _buildAmountRow('Total', _invoice!.totalAmount, isTotal: true),
            _buildAmountRow('Paid', _invoice!.paidAmount, isPaid: true),
            if (_invoice!.balanceAmount > 0)
              _buildAmountRow(
                'Balance Due',
                _invoice!.balanceAmount,
                isBalance: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isPaid = false,
    bool isBalance = false,
    bool isDiscount = false,
  }) {
    Color? textColor;
    if (isTotal || isBalance) {
      textColor = const Color(0xFFCF2049);
    } else if (isPaid) {
      textColor = Colors.green;
    } else if (isDiscount) {
      textColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}RM ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection() {
    if (_payments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._payments.map((payment) => _buildPaymentRow(payment)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(Map<String, dynamic> payment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['method'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(DateTime.parse(payment['createdAt'] ?? DateTime.now().toIso8601String())),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            'RM ${(payment['amount'] ?? 0.0).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: payment['status'] == 'completed'
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_invoice!.isPaid) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              const Text(
                'This invoice has been fully paid',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToPayment(),
                icon: const Icon(Icons.payment),
                label: Text(
                  _invoice!.balanceAmount > 0
                      ? 'Pay RM ${_invoice!.balanceAmount.toStringAsFixed(2)}'
                      : 'Make Payment',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCF2049),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_invoice!.balanceAmount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Balance due: RM ${_invoice!.balanceAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, color: Colors.orange[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(InvoiceStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case InvoiceStatus.draft:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[700]!;
        break;
      case InvoiceStatus.sent:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        break;
      case InvoiceStatus.paid:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        break;
      case InvoiceStatus.overdue:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        break;
      case InvoiceStatus.cancelled:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[600]!;
        break;
      case InvoiceStatus.refunded:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Future<void> _navigateToPayment() async {
    try {
      // Get customer information
      final customerProvider = Provider.of<CustomerProvider>(
        context,
        listen: false,
      );
      final customer = customerProvider.currentCustomer;

      if (customer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer information not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create payment request
      final paymentRequest = payment_model.CreatePaymentRequest(
        amount: _invoice!.balanceAmount,
        description: 'Payment for Invoice ${_invoice!.invoiceNumber}',
        customerName: customer.fullName ?? 'Customer',
        customerEmail: customer.email ?? '',
        customerPhone: customer.phoneNumber ?? '',
        orderId: _invoice!.invoiceNumber,
      );

      // Navigate to payment screen with callback
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            paymentRequest: paymentRequest,
            onPaymentComplete: (success) async {
              if (success) {
                // Payment was successful, update invoice status and refresh
                await _updateInvoiceAfterPayment();
                _loadInvoiceDetails();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment completed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              // Navigate back to invoice details
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateInvoiceAfterPayment() async {
    try {
      // Update invoice status to paid and update payment amounts
      await _billingService.processBillplzPayment(
        invoiceId: _invoice!.id,
        amount: _invoice!.balanceAmount,
        billplzBillId: 'BILLPLZ_${DateTime.now().millisecondsSinceEpoch}',
        notes: 'Payment via Billplz',
      );
      
      print('✅ Invoice ${_invoice!.invoiceNumber} updated after payment');
    } catch (e) {
      print('❌ Error updating invoice after payment: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
