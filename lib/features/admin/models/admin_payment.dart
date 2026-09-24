class AdminPayment {
  const AdminPayment({
    required this.id,
    required this.companyName,
    required this.planName,
    required this.amount,
    required this.billingCycle,
    required this.method,
    this.reference,
    required this.paidAt,
    required this.recordedByName,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) => AdminPayment(
        id: json['id'] as int,
        companyName: (json['company'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown shop',
        planName: (json['plan'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown plan',
        amount: double.parse(json['amount'].toString()),
        billingCycle: json['billing_cycle'] as String,
        method: json['method'] as String,
        reference: json['reference'] as String?,
        paidAt: DateTime.parse(json['paid_at'] as String),
        recordedByName: (json['recorded_by'] as Map<String, dynamic>?)?['name'] as String? ?? '—',
      );

  final int id;
  final String companyName;
  final String planName;
  final double amount;
  final String billingCycle;
  final String method;
  final String? reference;
  final DateTime paidAt;
  final String recordedByName;
}
