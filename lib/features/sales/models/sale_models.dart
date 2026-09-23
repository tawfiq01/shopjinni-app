class PosCandidate {
  const PosCandidate({
    required this.kind,
    required this.productVariantColorId,
    required this.displayName,
    this.imeiUnitId,
    this.imei1,
    required this.isDemo,
    this.availableQuantity,
    this.demoQuantity = 0,
    this.sellingPriceCurrent,
  });

  factory PosCandidate.fromJson(Map<String, dynamic> json) => PosCandidate(
        kind: json['kind'] as String,
        productVariantColorId: json['product_variant_color_id'] as int,
        displayName: json['display_name'] as String,
        imeiUnitId: json['imei_unit_id'] as int?,
        imei1: json['imei1'] as String?,
        isDemo: json['is_demo'] as bool? ?? false,
        availableQuantity: json['available_quantity'] as int?,
        demoQuantity: json['demo_quantity'] as int? ?? 0,
        sellingPriceCurrent: json['selling_price_current'] == null
            ? null
            : double.tryParse('${json['selling_price_current']}'),
      );

  final String kind; // 'imei' or 'quantity'
  final int productVariantColorId;
  final String displayName;
  final int? imeiUnitId;
  final String? imei1;
  final bool isDemo;
  final int? availableQuantity;
  final int demoQuantity;
  final double? sellingPriceCurrent;

  bool get isImei => kind == 'imei';
}

class SaleItemSummary {
  const SaleItemSummary({
    required this.id,
    required this.displayName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.imei,
    required this.isDemo,
    this.profit,
  });

  factory SaleItemSummary.fromJson(Map<String, dynamic> json) => SaleItemSummary(
        id: json['id'] as int,
        displayName: json['display_name'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unit_price'] as num).toDouble(),
        lineTotal: (json['line_total'] as num).toDouble(),
        imei: json['imei'] as String?,
        isDemo: json['is_demo'] as bool? ?? false,
        profit: json['profit'] == null ? null : (json['profit'] as num).toDouble(),
      );

  final int id;
  final String displayName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? imei;
  final bool isDemo;
  final double? profit;
}

class SalesInvoiceSummary {
  const SalesInvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    required this.saleDate,
    required this.total,
    required this.paidAmount,
    required this.dueAmount,
    required this.items,
    this.customerId,
    this.customerName,
    this.profit,
  });

  factory SalesInvoiceSummary.fromJson(Map<String, dynamic> json) => SalesInvoiceSummary(
        id: json['id'] as int,
        invoiceNumber: json['invoice_number'] as String,
        saleDate: json['sale_date'] as String,
        customerId: json['customer']?['id'] as int?,
        customerName: json['customer']?['name'] as String?,
        total: (json['total'] as num).toDouble(),
        paidAmount: (json['paid_amount'] as num).toDouble(),
        dueAmount: (json['due_amount'] as num).toDouble(),
        profit: json['profit'] == null ? null : (json['profit'] as num).toDouble(),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => SaleItemSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String invoiceNumber;
  final String saleDate;
  final int? customerId;
  final String? customerName;
  final double total;
  final double paidAmount;
  final double dueAmount;
  final double? profit;
  final List<SaleItemSummary> items;
}
