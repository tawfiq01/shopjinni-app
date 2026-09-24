class CompanyDetails {
  const CompanyDetails({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.logoUrl,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) => CompanyDetails(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        logoUrl: json['logo_url'] as String?,
      );

  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? logoUrl;
}
