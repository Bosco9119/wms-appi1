import 'billing_item_model.dart';
import 'payment_model.dart';

enum InvoiceStatus {
  draft,
  sent,
  paid,
  overdue,
  cancelled,
  refunded,
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String shopId;
  final String shopName;
  final String? bookingId;
  final InvoiceStatus status;
  final List<BillingItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final DateTime issueDate;
  final DateTime dueDate;
  final String? notes;
  final String? terms;
  final List<Payment> payments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.shopId,
    required this.shopName,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.issueDate,
    required this.dueDate,
    required this.payments,
    required this.createdAt,
    required this.updatedAt,
    this.customerPhone,
    this.bookingId,
    this.notes,
    this.terms,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      customerPhone: json['customerPhone'],
      shopId: json['shopId'] ?? '',
      shopName: json['shopName'] ?? '',
      bookingId: json['bookingId'],
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => BillingItem.fromJson(item))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      taxRate: (json['taxRate'] ?? 0.0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0.0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0.0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0.0).toDouble(),
      balanceAmount: (json['balanceAmount'] ?? 0.0).toDouble(),
      issueDate: DateTime.parse(json['issueDate'] ?? DateTime.now().toIso8601String()),
      dueDate: DateTime.parse(json['dueDate'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
      notes: json['notes'],
      terms: json['terms'],
      payments: (json['payments'] as List<dynamic>?)
          ?.map((payment) => Payment.fromJson(payment))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'shopId': shopId,
      'shopName': shopName,
      'bookingId': bookingId,
      'status': status.name,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'notes': notes,
      'terms': terms,
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? shopId,
    String? shopName,
    String? bookingId,
    InvoiceStatus? status,
    List<BillingItem>? items,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    double? paidAmount,
    double? balanceAmount,
    DateTime? issueDate,
    DateTime? dueDate,
    String? notes,
    String? terms,
    List<Payment>? payments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      bookingId: bookingId ?? this.bookingId,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      payments: payments ?? this.payments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
      case InvoiceStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isPaid => status == InvoiceStatus.paid;
  bool get isOverdue => status == InvoiceStatus.overdue;
  bool get isDraft => status == InvoiceStatus.draft;
  bool get isSent => status == InvoiceStatus.sent;

  double get paymentProgress => totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;

  @override
  String toString() {
    return 'Invoice(id: $id, invoiceNumber: $invoiceNumber, status: $statusDisplayName, totalAmount: $totalAmount)';
  }
}