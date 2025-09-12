enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  digitalWallet,
  other,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
  cancelled,
}

class Payment {
  final String id;
  final String invoiceId;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final String? transactionId;
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.method,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.transactionId,
    this.reference,
    this.notes,
    this.completedAt,
    this.failureReason,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? '',
      invoiceId: json['invoiceId'] ?? '',
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      amount: (json['amount'] ?? 0.0).toDouble(),
      transactionId: json['transactionId'],
      reference: json['reference'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      failureReason: json['failureReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'method': method.name,
      'status': status.name,
      'amount': amount,
      'transactionId': transactionId,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'failureReason': failureReason,
    };
  }

  Payment copyWith({
    String? id,
    String? invoiceId,
    PaymentMethod? method,
    PaymentStatus? status,
    double? amount,
    String? transactionId,
    String? reference,
    String? notes,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
  }) {
    return Payment(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      method: method ?? this.method,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      transactionId: transactionId ?? this.transactionId,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  String get methodDisplayName {
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

  String get statusDisplayName {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  String toString() {
    return 'Payment(id: $id, method: $methodDisplayName, status: $statusDisplayName, amount: $amount)';
  }
}
