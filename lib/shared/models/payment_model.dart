class PaymentModel {
  final String billId;
  final String orderId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final double amount;
  final String description;
  final PaymentStatus status;
  final String billUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? transactionId;
  final DateTime? paidAt;

  PaymentModel({
    required this.billId,
    required this.orderId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.amount,
    required this.description,
    required this.status,
    required this.billUrl,
    required this.createdAt,
    required this.updatedAt,
    this.transactionId,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      billId: json['billId'] ?? '',
      orderId: json['orderId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      customerPhone: json['customerPhone'],
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      status: PaymentStatus.fromString(json['status'] ?? 'pending'),
      billUrl: json['billUrl'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toDate().toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toDate().toString())
          : DateTime.now(),
      transactionId: json['transactionId'],
      paidAt: json['paidAt'] != null 
          ? DateTime.parse(json['paidAt'].toDate().toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'billId': billId,
      'orderId': orderId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'amount': amount,
      'description': description,
      'status': status.value,
      'billUrl': billUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'transactionId': transactionId,
      'paidAt': paidAt,
    };
  }

  PaymentModel copyWith({
    String? billId,
    String? orderId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    double? amount,
    String? description,
    PaymentStatus? status,
    String? billUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? transactionId,
    DateTime? paidAt,
  }) {
    return PaymentModel(
      billId: billId ?? this.billId,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      billUrl: billUrl ?? this.billUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactionId: transactionId ?? this.transactionId,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}

enum PaymentStatus {
  pending('pending'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
      case 'paid':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
      case 'canceled':
        return PaymentStatus.cancelled;
      default:
        return PaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class CreatePaymentRequest {
  final double amount;
  final String description;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? orderId;

  CreatePaymentRequest({
    required this.amount,
    required this.description,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'orderId': orderId,
    };
  }
}

class PaymentResponse {
  final bool success;
  final String? billId;
  final String? billUrl;
  final String? message;
  final PaymentModel? payment;
  final List<PaymentModel>? payments;

  PaymentResponse({
    required this.success,
    this.billId,
    this.billUrl,
    this.message,
    this.payment,
    this.payments,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      billId: json['billId'],
      billUrl: json['billUrl'],
      message: json['message'],
      payment: json['payment'] != null 
          ? PaymentModel.fromJson(json['payment'])
          : null,
      payments: json['payments'] != null
          ? (json['payments'] as List)
              .map((p) => PaymentModel.fromJson(p))
              .toList()
          : null,
    );
  }
}