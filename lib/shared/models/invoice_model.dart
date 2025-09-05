class Invoice {
  final String id;
  final String appointmentId;
  final String customerId;
  final String workshopId;
  final String workshopName;
  final String invoiceNumber;
  final double totalAmount;
  final double taxAmount;
  final double discountAmount;
  final double finalAmount;
  final String status;
  final String? paymentMethod;
  final DateTime? paymentDate;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.appointmentId,
    required this.customerId,
    required this.workshopId,
    required this.workshopName,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.status,
    this.paymentMethod,
    this.paymentDate,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] ?? '',
      appointmentId: map['appointment_id'] ?? '',
      customerId: map['customer_id'] ?? '',
      workshopId: map['workshop_id'] ?? '',
      workshopName: map['workshop_name'] ?? '',
      invoiceNumber: map['invoice_number'] ?? '',
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      taxAmount: (map['tax_amount'] ?? 0.0).toDouble(),
      discountAmount: (map['discount_amount'] ?? 0.0).toDouble(),
      finalAmount: (map['final_amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Pending',
      paymentMethod: map['payment_method'],
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'])
          : null,
      dueDate: DateTime.parse(
        map['due_date'] ??
            DateTime.now().add(Duration(days: 30)).toIso8601String(),
      ),
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appointment_id': appointmentId,
      'customer_id': customerId,
      'workshop_id': workshopId,
      'workshop_name': workshopName,
      'invoice_number': invoiceNumber,
      'total_amount': totalAmount,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
      'status': status,
      'payment_method': paymentMethod,
      'payment_date': paymentDate?.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Invoice copyWith({
    String? id,
    String? appointmentId,
    String? customerId,
    String? workshopId,
    String? workshopName,
    String? invoiceNumber,
    double? totalAmount,
    double? taxAmount,
    double? discountAmount,
    double? finalAmount,
    String? status,
    String? paymentMethod,
    DateTime? paymentDate,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      customerId: customerId ?? this.customerId,
      workshopId: workshopId ?? this.workshopId,
      workshopName: workshopName ?? this.workshopName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPaid => status == 'Paid';
  bool get isPending => status == 'Pending';
  bool get isOverdue => status == 'Overdue';
  bool get isCancelled => status == 'Cancelled';

  bool get isOverduePayment {
    if (isPaid || isCancelled) return false;
    return DateTime.now().isAfter(dueDate);
  }

  String get statusDisplayName {
    switch (status) {
      case 'Pending':
        return 'Pending Payment';
      case 'Paid':
        return 'Paid';
      case 'Overdue':
        return 'Overdue';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get formattedAmount => 'RM ${finalAmount.toStringAsFixed(2)}';
  String get formattedTotalAmount => 'RM ${totalAmount.toStringAsFixed(2)}';
  String get formattedTaxAmount => 'RM ${taxAmount.toStringAsFixed(2)}';
  String get formattedDiscountAmount =>
      'RM ${discountAmount.toStringAsFixed(2)}';

  String get formattedDueDate {
    return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
  }

  String get formattedPaymentDate {
    if (paymentDate == null) return 'Not paid';
    return '${paymentDate!.day}/${paymentDate!.month}/${paymentDate!.year}';
  }

  @override
  String toString() {
    return 'Invoice(id: $id, invoiceNumber: $invoiceNumber, finalAmount: $finalAmount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class InvoiceItem {
  final String id;
  final String invoiceId;
  final String itemName;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;

  InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.itemName,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] ?? '',
      invoiceId: map['invoice_id'] ?? '',
      itemName: map['item_name'] ?? '',
      description: map['description'],
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unit_price'] ?? 0.0).toDouble(),
      totalPrice: (map['total_price'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'item_name': itemName,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedUnitPrice => 'RM ${unitPrice.toStringAsFixed(2)}';
  String get formattedTotalPrice => 'RM ${totalPrice.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'InvoiceItem(id: $id, itemName: $itemName, quantity: $quantity, totalPrice: $totalPrice)';
  }
}
