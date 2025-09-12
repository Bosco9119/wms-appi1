import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/billing_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/providers/customer_provider.dart';
import 'package:provider/provider.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final BillingService _billingService = BillingService();
  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customerProvider = Provider.of<CustomerProvider>(
        context,
        listen: false,
      );
      final customer = customerProvider.currentCustomer;

      print('🔍 Loading invoices for customer: ${customer?.id}');
      print('   👤 Customer name: ${customer?.fullName}');
      print('   📧 Customer email: ${customer?.email}');

      if (customer != null) {
        final invoices = await _billingService.getCustomerInvoices(customer.id);
        print('📄 Found ${invoices.length} invoices');
        for (final invoice in invoices) {
          print(
            '   📋 Invoice: ${invoice.invoiceNumber} - RM ${invoice.totalAmount.toStringAsFixed(2)}',
          );
        }

        setState(() {
          _invoices = invoices;
          _isLoading = false;
        });
      } else {
        print('❌ Customer is null');
        setState(() {
          _errorMessage = 'Customer not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading invoices: $e');
      setState(() {
        _errorMessage = 'Failed to load invoices: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Invoices'),
        backgroundColor: const Color(0xFFCF2049),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInvoices),
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
              onPressed: _loadInvoices,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No invoices found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your invoices will appear here once you have bookings',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInvoices,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invoices.length,
        itemBuilder: (context, index) {
          final invoice = _invoices[index];
          return _buildInvoiceCard(invoice);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('${RouteNames.invoiceDetails}/${invoice.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(invoice.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                invoice.shopName,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Issue Date: ${_formatDate(invoice.issueDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: RM ${invoice.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCF2049),
                    ),
                  ),
                  if (invoice.balanceAmount > 0)
                    Text(
                      'Balance: RM ${invoice.balanceAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                    ),
                ],
              ),
              if (invoice.balanceAmount > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: invoice.paymentProgress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    invoice.paymentProgress == 100
                        ? Colors.green
                        : const Color(0xFFCF2049),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${invoice.paymentProgress.toStringAsFixed(0)}% paid',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
