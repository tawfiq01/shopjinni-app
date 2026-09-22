class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.isMain,
    required this.isActive,
    this.address,
    this.phone,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id'] as int,
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        isMain: json['is_main'] as bool,
        isActive: json['is_active'] as bool,
      );

  final int id;
  final String name;
  final String? address;
  final String? phone;
  final bool isMain;
  final bool isActive;
}
