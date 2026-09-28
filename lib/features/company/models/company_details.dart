class CompanyDetails {
  const CompanyDetails({
    required this.id,
    required this.name,
    this.ownerName,
    this.address,
    this.district,
    this.country,
    this.currency,
    this.timezone,
    this.phone,
    this.logoUrl,
    this.setupWizardCompleted = false,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) => CompanyDetails(
        id: json['id'] as int,
        name: json['name'] as String,
        ownerName: json['owner_name'] as String?,
        address: json['address'] as String?,
        district: json['district'] as String?,
        country: json['country'] as String?,
        currency: json['currency'] as String?,
        timezone: json['timezone'] as String?,
        phone: json['phone'] as String?,
        logoUrl: json['logo_url'] as String?,
        setupWizardCompleted: json['setup_wizard_completed'] as bool? ?? false,
      );

  final int id;
  final String name;
  final String? ownerName;
  final String? address;
  final String? district;
  final String? country;
  final String? currency;
  final String? timezone;
  final String? phone;
  final String? logoUrl;
  final bool setupWizardCompleted;
}
