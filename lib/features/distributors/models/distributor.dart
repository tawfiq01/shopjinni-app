class Distributor {
  const Distributor({
    required this.id,
    required this.name,
    required this.mobile,
    required this.openingBalance,
    required this.currentBalance,
    required this.isActive,
    this.companyName,
    this.contactPerson,
    this.altMobile,
    this.address,
    this.email,
    this.creditLimit,
    this.paymentTerms,
    this.notes,
  });

  factory Distributor.fromJson(Map<String, dynamic> json) => Distributor(
        id: json['id'] as int,
        name: json['name'] as String,
        companyName: json['company_name'] as String?,
        contactPerson: json['contact_person'] as String?,
        mobile: json['mobile'] as String,
        altMobile: json['alt_mobile'] as String?,
        address: json['address'] as String?,
        email: json['email'] as String?,
        openingBalance: double.tryParse('${json['opening_balance']}') ?? 0,
        creditLimit: json['credit_limit'] == null ? null : double.tryParse('${json['credit_limit']}'),
        paymentTerms: json['payment_terms'] as String?,
        notes: json['notes'] as String?,
        isActive: json['is_active'] as bool,
        currentBalance: (json['current_balance'] as num).toDouble(),
      );

  final int id;
  final String name;
  final String? companyName;
  final String? contactPerson;
  final String mobile;
  final String? altMobile;
  final String? address;
  final String? email;
  final double openingBalance;
  final double? creditLimit;
  final String? paymentTerms;
  final String? notes;
  final bool isActive;
  final double currentBalance;
}
