class StockTransferItemSummary {
  const StockTransferItemSummary({
    required this.id,
    required this.displayName,
    required this.quantity,
    this.imei,
  });

  factory StockTransferItemSummary.fromJson(Map<String, dynamic> json) => StockTransferItemSummary(
        id: json['id'] as int,
        displayName: json['display_name'] as String,
        quantity: json['quantity'] as int,
        imei: json['imei'] as String?,
      );

  final int id;
  final String displayName;
  final int quantity;
  final String? imei;
}

class StockTransferSummary {
  const StockTransferSummary({
    required this.id,
    required this.transferDate,
    required this.fromBranchName,
    required this.toBranchName,
    required this.items,
    this.notes,
  });

  factory StockTransferSummary.fromJson(Map<String, dynamic> json) => StockTransferSummary(
        id: json['id'] as int,
        transferDate: json['transfer_date'] as String,
        fromBranchName: json['from_branch']['name'] as String,
        toBranchName: json['to_branch']['name'] as String,
        notes: json['notes'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => StockTransferItemSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String transferDate;
  final String fromBranchName;
  final String toBranchName;
  final String? notes;
  final List<StockTransferItemSummary> items;
}
