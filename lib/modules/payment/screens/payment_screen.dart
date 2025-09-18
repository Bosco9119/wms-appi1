import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/constants/payment_constants.dart';
import '../../../shared/models/payment_model.dart';

class PaymentScreen extends StatefulWidget {
  final CreatePaymentRequest paymentRequest;
  final Function(bool)? onPaymentComplete;

  const PaymentScreen({
    Key? key,
    required this.paymentRequest,
    this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late WebViewController _webViewController;
  final PaymentService _paymentService = PaymentService();
  PaymentModel? _payment;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createPayment();
  }

  Future<void> _createPayment() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _paymentService.createBill(widget.paymentRequest);
      
      if (response.success && response.billId != null && response.billUrl != null) {
        setState(() {
          _payment = PaymentModel(
            billId: response.billId!,
            orderId: widget.paymentRequest.orderId ?? '',
            customerName: widget.paymentRequest.customerName,
            customerEmail: widget.paymentRequest.customerEmail,
            customerPhone: widget.paymentRequest.customerPhone,
            amount: widget.paymentRequest.amount,
            description: widget.paymentRequest.description,
            status: PaymentStatus.pending,
            billUrl: response.billUrl!,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _isLoading = false;
        });

        // Listen to payment status changes
        _paymentService.listenToPaymentStatus(response.billId!).listen((payment) {
          if (payment != null && mounted) {
            // Check if payment is completed
            if (_paymentService.isPaymentCompleted(payment.status)) {
              _showPaymentResult(true, 'Payment completed successfully!');
            } else if (_paymentService.isPaymentFailed(payment.status)) {
              _showPaymentResult(false, 'Payment failed. Please try again.');
            }
          }
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to create payment';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating payment: $e';
        _isLoading = false;
      });
    }
  }

  void _handlePaymentRedirect(String url) {
    print('Payment redirect detected: $url');
    
    // Determine if payment was successful based on URL
    // Billplz success URLs typically contain 'completion' or 'success'
    bool isSuccess = url.contains('payment=success') || 
                    url.contains('payment-success') || 
                    url.contains('httpbin.org') ||
                    url.contains('completion') ||
                    url.contains('success');
    
    print('Payment success status: $isSuccess');
    
    // Update payment status in Firestore if successful
    if (isSuccess && _payment != null) {
      _updatePaymentStatus(PaymentStatus.completed);
    } else if (!isSuccess && _payment != null) {
      _updatePaymentStatus(PaymentStatus.failed);
    }
    
    // Show payment result
    _showPaymentResult(isSuccess, isSuccess ? 'Payment completed successfully!' : 'Payment failed. Please try again.');
  }

  Future<void> _updatePaymentStatus(PaymentStatus status) async {
    if (_payment == null) return;
    
    try {
      await _paymentService.updatePaymentStatus(_payment!.billId, status);
      print('✅ Payment status updated to: ${status.displayName}');
    } catch (e) {
      print('❌ Error updating payment status: $e');
    }
  }

  void _showPaymentResult(bool success, String message) {
    print('Showing payment result dialog: success=$success, message=$message');
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Payment Success' : 'Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              print('OK button pressed, closing dialog and navigating back');
              
              // Close the dialog
              Navigator.of(context).pop();
              
              // Use callback if available, otherwise use Navigator
              if (widget.onPaymentComplete != null) {
                widget.onPaymentComplete!(success);
              } else {
                // Fallback to Navigator
                if (mounted) {
                  Navigator.of(context).pop(success);
                }
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
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
            Text('Creating payment...'),
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
                'Payment Error',
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
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _createPayment();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    }

    if (_payment != null) {
      return Column(
        children: [
          _buildPaymentInfo(),
          Expanded(
            child: WebViewWidget(
              controller: _webViewController = WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onPageStarted: (String url) {
                      // Handle page navigation if needed
                      print('WebView navigating to: $url');
                    },
                    onPageFinished: (String url) {
                      // Handle page finished loading
                      print('WebView finished loading: $url');
                      
                      // Check if this is a redirect URL (success/failure)
                      if (url.contains('httpbin.org') || 
                          url.contains('payment-success') || 
                          url.contains('payment-failed') ||
                          url.contains('completion') ||
                          url.contains('success')) {
                        // This means payment was completed
                        _handlePaymentRedirect(url);
                      }
                    },
                    onNavigationRequest: (NavigationRequest request) {
                      print('WebView navigation request: ${request.url}');
                      
                      // Check if this is a redirect URL
                      if (request.url.contains('httpbin.org') || 
                          request.url.contains('payment=success') ||
                          request.url.contains('payment-success') || 
                          request.url.contains('payment-failed') ||
                          request.url.contains('completion') ||
                          request.url.contains('success')) {
                        // This means payment was completed
                        _handlePaymentRedirect(request.url);
                        return NavigationDecision.prevent;
                      }
                      
                      return NavigationDecision.navigate;
                    },
                  ),
                )
                ..loadRequest(Uri.parse(_payment!.billUrl)),
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Text('No payment information available'),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _paymentService.formatAmount(_payment!.amount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Description: ${_payment!.description}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Customer: ${_payment!.customerName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
