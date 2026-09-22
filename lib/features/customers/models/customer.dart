class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.openingBalance,
    required this.currentBalance,
    required this.isActive,
    this.address,
    this.email,
    this.creditLimit,
    this.notes,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as int,
        name: json['name'] as String,
        mobile: json['mobile'] as String,
        address: json['address'] as String?,
        email: json['email'] as String?,
        openingBalance: double.tryParse('${json['opening_balance']}') ?? 0,
        creditLimit: json['credit_limit'] == null ? null : double.tryParse('${json['credit_limit']}'),
        notes: json['notes'] as String?,
        isActive: json['is_active'] as bool,
        currentBalance: (json['current_balance'] as num).toDouble(),
      );

  final int id;
  final String name;
  final String mobile;
  final String? address;
  final String? email;
  final double openingBalance;
  final double? creditLimit;
  final String? notes;
  final bool isActive;
  final double currentBalance;
}
