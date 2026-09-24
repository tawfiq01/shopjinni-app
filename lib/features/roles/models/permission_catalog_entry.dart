class PermissionCatalogEntry {
  const PermissionCatalogEntry({required this.key, required this.label});

  factory PermissionCatalogEntry.fromJson(Map<String, dynamic> json) => PermissionCatalogEntry(
        key: json['key'] as String,
        label: json['label'] as String,
      );

  final String key;
  final String label;
}
