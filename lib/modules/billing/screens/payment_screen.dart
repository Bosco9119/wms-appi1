import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/billing_service.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/models/payment_model.dart';

class PaymentScreen extends StatefulWidget {
  final Invoice invoice;
  final VoidCallback onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.invoice,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final BillingService _billingService = BillingService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.invoice.balanceAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInvoiceSummary(),
              const SizedBox(height: 24),
              _buildPaymentMethodSelection(),
              const SizedBox(height: 24),
              _buildPaymentForm(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoice Number:'),
                Text(
                  widget.invoice.invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:'),
                Text(
                  'RM ${widget.invoice.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Paid Amount:'),
                Text(
                  'RM ${widget.invoice.paidAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Balance Due:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'RM ${widget.invoice.balanceAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCF2049),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...PaymentMethod.values.map((method) => _buildPaymentMethodTile(method)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    return RadioListTile<PaymentMethod>(
      title: Text(_getPaymentMethodDisplayName(method)),
      subtitle: Text(_getPaymentMethodDescription(method)),
      value: method,
      groupValue: _selectedMethod,
      onChanged: (value) {
        setState(() {
          _selectedMethod = value!;
        });
      },
      activeColor: const Color(0xFFCF2049),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (RM)',
                prefixText: 'RM ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter payment amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount > widget.invoice.balanceAmount) {
                  return 'Amount cannot exceed balance due';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_selectedMethod != PaymentMethod.cash) ...[
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Reference',
                  hintText: 'Enter transaction ID or reference',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_selectedMethod != PaymentMethod.cash && 
                      (value == null || value.isEmpty)) {
                    return 'Transaction reference is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add any additional notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF2049),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Process Payment'),
          ),
        ),
      ],
    );
  }

  String _getPaymentMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Pay with cash at the service center';
      case PaymentMethod.creditCard:
        return 'Pay with credit card';
      case PaymentMethod.debitCard:
        return 'Pay with debit card';
      case PaymentMethod.bankTransfer:
        return 'Transfer to bank account';
      case PaymentMethod.digitalWallet:
        return 'Pay with digital wallet (GrabPay, Touch n Go, etc.)';
      case PaymentMethod.other:
        return 'Other payment method';
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final reference = _referenceController.text.trim();
      final notes = _notesController.text.trim();

      final payment = await _billingService.processPayment(
        invoiceId: widget.invoice.id,
        method: _selectedMethod,
        amount: amount,
        transactionId: reference.isNotEmpty ? reference : null,
        reference: reference.isNotEmpty ? reference : null,
        notes: notes.isNotEmpty ? notes : null,
      );

      if (payment != null) {
        widget.onPaymentSuccess();
        Navigator.of(context).pop();
      } else {
        _showErrorMessage('Failed to process payment. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('Error processing payment: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}