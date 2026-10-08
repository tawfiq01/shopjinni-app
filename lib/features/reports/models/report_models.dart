// Laravel's `decimal:N` casts (used on every money/cost column) serialize
// to JSON as strings (e.g. "20000.00"), not numbers — `as num` crashes the
// instant a backend field changes from a plain column to a decimal cast.
// These helpers accept either so a cast-type change on the backend can't
// silently break every report screen that reads a cost/total field.
double _toDouble(dynamic value) =>
    value is num ? value.toDouble() : double.parse(value as String);

double? _toDoubleOrNull(dynamic value) =>
    value == null ? null : _toDouble(value);

class StockReportRow {
  const StockReportRow({
    required this.skuId,
    required this.sku,
    required this.displayName,
    required this.brand,
    required this.model,
    required this.variantLabel,
    required this.color,
    required this.productType,
    required this.quantity,
    required this.demoQuantity,
    required this.reorderLevel,
    required this.isLowStock,
    required this.imeiTrackingEnabled,
    this.unitCost,
    this.value,
  });

  factory StockReportRow.fromJson(Map<String, dynamic> json) => StockReportRow(
    skuId: json['sku_id'] as int,
    sku: json['sku'] as String,
    displayName: json['display_name'] as String,
    brand: json['brand'] as String,
    model: json['model'] as String,
    variantLabel: json['variant_label'] as String? ?? '',
    color: json['color'] as String,
    productType: json['product_type'] as String,
    quantity: json['quantity'] as int,
    demoQuantity: json['demo_quantity'] as int? ?? 0,
    reorderLevel: json['reorder_level'] as int,
    isLowStock: json['is_low_stock'] as bool,
    imeiTrackingEnabled: json['imei_tracking_enabled'] as bool,
    unitCost: _toDoubleOrNull(json['unit_cost']),
    value: _toDoubleOrNull(json['value']),
  );

  final int skuId;
  final String sku;
  final String displayName;
  final String brand;
  final String model;
  final String variantLabel;
  final String color;
  final String productType;
  final int quantity;

  /// How many of [quantity] are marked as demo/display units.
  final int demoQuantity;
  final int reorderLevel;
  final bool isLowStock;
  final bool imeiTrackingEnabled;

  /// Null when the viewer lacks reports.view-cost.
  final double? unitCost;
  final double? value;
}

class StockReport {
  const StockReport({required this.rows, this.totalValue});

  factory StockReport.fromJson(Map<String, dynamic> json) => StockReport(
    rows: (json['data'] as List<dynamic>)
        .map((e) => StockReportRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalValue: _toDoubleOrNull(json['total_value']),
  );

  final List<StockReportRow> rows;
  final double? totalValue;
}

class DailyTotal {
  const DailyTotal({
    required this.date,
    required this.total,
    required this.count,
  });

  factory DailyTotal.fromJson(Map<String, dynamic> json) => DailyTotal(
    date: json['date'] as String,
    total: _toDouble(json['total']),
    count: json['count'] as int,
  );

  final String date;
  final double total;
  final int count;
}

class SalesGroupTotal {
  const SalesGroupTotal({
    required this.name,
    required this.quantity,
    required this.total,
  });

  factory SalesGroupTotal.fromJson(Map<String, dynamic> json, String nameKey) =>
      SalesGroupTotal(
        name: json[nameKey] as String,
        quantity: json['quantity'] as int,
        total: _toDouble(json['total']),
      );

  final String name;
  final int quantity;
  final double total;
}

class NamedTotal {
  const NamedTotal({
    required this.name,
    required this.total,
    required this.count,
  });

  factory NamedTotal.fromJson(Map<String, dynamic> json) => NamedTotal(
    name: json['name'] as String,
    total: _toDouble(json['total']),
    count: json['count'] as int,
  );

  final String name;
  final double total;
  final int count;
}

class SalesSummary {
  const SalesSummary({
    required this.from,
    required this.to,
    required this.invoiceCount,
    required this.totalSales,
    required this.totalDiscount,
    required this.totalDue,
    required this.byDay,
    required this.byModel,
    required this.byColor,
    required this.bySalesperson,
    required this.byCustomer,
    this.totalProfit,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) => SalesSummary(
    from: json['from'] as String,
    to: json['to'] as String,
    invoiceCount: json['invoice_count'] as int,
    totalSales: _toDouble(json['total_sales']),
    totalDiscount: _toDouble(json['total_discount']),
    totalDue: _toDouble(json['total_due']),
    totalProfit: _toDoubleOrNull(json['total_profit']),
    byDay: (json['by_day'] as List<dynamic>? ?? [])
        .map((e) => DailyTotal.fromJson(e as Map<String, dynamic>))
        .toList(),
    byModel: (json['by_model'] as List<dynamic>? ?? [])
        .map(
          (e) =>
              SalesGroupTotal.fromJson(e as Map<String, dynamic>, 'model_name'),
        )
        .toList(),
    byColor: (json['by_color'] as List<dynamic>? ?? [])
        .map(
          (e) =>
              SalesGroupTotal.fromJson(e as Map<String, dynamic>, 'color_name'),
        )
        .toList(),
    bySalesperson: (json['by_salesperson'] as List<dynamic>? ?? [])
        .map((e) => NamedTotal.fromJson(e as Map<String, dynamic>))
        .toList(),
    byCustomer: (json['by_customer'] as List<dynamic>? ?? [])
        .map((e) => NamedTotal.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final String from;
  final String to;
  final int invoiceCount;
  final double totalSales;
  final double totalDiscount;
  final double totalDue;
  final double? totalProfit;
  final List<DailyTotal> byDay;
  final List<SalesGroupTotal> byModel;
  final List<SalesGroupTotal> byColor;
  final List<NamedTotal> bySalesperson;
  final List<NamedTotal> byCustomer;
}

class SalesDetailRow {
  const SalesDetailRow({
    required this.invoiceNumber,
    required this.saleDate,
    required this.sku,
    required this.displayName,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.lineTotal,
    required this.isDemo,
    this.customer,
    this.salesperson,
    this.branch,
    this.imei,
    this.unitCost,
    this.profit,
  });

  factory SalesDetailRow.fromJson(Map<String, dynamic> json) => SalesDetailRow(
    invoiceNumber: json['invoice_number'] as String,
    saleDate: json['sale_date'] as String,
    customer: json['customer'] as String?,
    salesperson: json['salesperson'] as String?,
    branch: json['branch'] as String?,
    sku: json['sku'] as String,
    displayName: json['display_name'] as String,
    imei: json['imei'] as String?,
    isDemo: json['is_demo'] as bool? ?? false,
    quantity: json['quantity'] as int,
    unitPrice: _toDouble(json['unit_price']),
    discount: _toDouble(json['discount']),
    lineTotal: _toDouble(json['line_total']),
    unitCost: _toDoubleOrNull(json['unit_cost']),
    profit: _toDoubleOrNull(json['profit']),
  );

  final String invoiceNumber;
  final String saleDate;
  final String? customer;
  final String? salesperson;
  final String? branch;
  final String sku;
  final String displayName;
  final String? imei;
  final bool isDemo;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double lineTotal;

  /// Null when the viewer lacks reports.view-cost.
  final double? unitCost;
  final double? profit;
}

class SalesDetailReport {
  const SalesDetailReport({
    required this.from,
    required this.to,
    required this.totalQuantity,
    required this.totalSales,
    required this.rows,
    this.totalProfit,
  });

  factory SalesDetailReport.fromJson(Map<String, dynamic> json) =>
      SalesDetailReport(
        from: json['from'] as String,
        to: json['to'] as String,
        totalQuantity: json['total_quantity'] as int,
        totalSales: _toDouble(json['total_sales']),
        totalProfit: _toDoubleOrNull(json['total_profit']),
        rows: (json['rows'] as List<dynamic>? ?? [])
            .map((e) => SalesDetailRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String from;
  final String to;
  final int totalQuantity;
  final double totalSales;
  final double? totalProfit;
  final List<SalesDetailRow> rows;
}

class DistributorPurchaseTotal {
  const DistributorPurchaseTotal({
    required this.distributorName,
    required this.total,
    required this.count,
  });

  factory DistributorPurchaseTotal.fromJson(Map<String, dynamic> json) =>
      DistributorPurchaseTotal(
        distributorName: json['distributor_name'] as String,
        total: _toDouble(json['total']),
        count: json['count'] as int,
      );

  final String distributorName;
  final double total;
  final int count;
}

class PurchaseProductTotal {
  const PurchaseProductTotal({
    required this.skuId,
    required this.displayName,
    required this.quantity,
    required this.total,
    required this.avgUnitCost,
  });

  factory PurchaseProductTotal.fromJson(Map<String, dynamic> json) =>
      PurchaseProductTotal(
        skuId: json['sku_id'] as int,
        displayName: json['display_name'] as String,
        quantity: json['quantity'] as int,
        total: _toDouble(json['total']),
        avgUnitCost: _toDouble(json['avg_unit_cost']),
      );

  final int skuId;
  final String displayName;
  final int quantity;
  final double total;
  final double avgUnitCost;
}

class PurchaseSummary {
  const PurchaseSummary({
    required this.from,
    required this.to,
    required this.invoiceCount,
    required this.totalPurchases,
    required this.totalDue,
    required this.byDistributor,
    required this.byProduct,
  });

  factory PurchaseSummary.fromJson(Map<String, dynamic> json) =>
      PurchaseSummary(
        from: json['from'] as String,
        to: json['to'] as String,
        invoiceCount: json['invoice_count'] as int,
        totalPurchases: _toDouble(json['total_purchases']),
        totalDue: _toDouble(json['total_due']),
        byDistributor: (json['by_distributor'] as List<dynamic>? ?? [])
            .map(
              (e) =>
                  DistributorPurchaseTotal.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        byProduct: (json['by_product'] as List<dynamic>? ?? [])
            .map(
              (e) => PurchaseProductTotal.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );

  final String from;
  final String to;
  final int invoiceCount;
  final double totalPurchases;
  final double totalDue;
  final List<DistributorPurchaseTotal> byDistributor;
  final List<PurchaseProductTotal> byProduct;
}

class PurchasePriceHistoryRow {
  const PurchasePriceHistoryRow({
    required this.purchaseItemId,
    required this.date,
    required this.invoiceNumber,
    required this.distributorName,
    required this.quantity,
    required this.unitCost,
    required this.remainingQuantity,
  });

  factory PurchasePriceHistoryRow.fromJson(Map<String, dynamic> json) =>
      PurchasePriceHistoryRow(
        purchaseItemId: json['purchase_item_id'] as int,
        date: json['date'] as String,
        invoiceNumber: json['invoice_number'] as String,
        distributorName: json['distributor_name'] as String,
        quantity: json['quantity'] as int,
        unitCost: _toDouble(json['unit_cost']),
        remainingQuantity: json['remaining_quantity'] as int,
      );

  final int purchaseItemId;
  final String date;
  final String invoiceNumber;
  final String distributorName;
  final int quantity;
  final double unitCost;
  final int remainingQuantity;
}

class DueRow {
  const DueRow({
    required this.id,
    required this.name,
    required this.mobile,
    required this.due,
  });

  factory DueRow.fromJson(Map<String, dynamic> json) => DueRow(
    id: json['id'] as int,
    name: json['name'] as String,
    mobile: json['mobile'] as String,
    due: _toDouble(json['due']),
  );

  final int id;
  final String name;
  final String mobile;
  final double due;
}

class DuesReport {
  const DuesReport({
    required this.customers,
    required this.distributors,
    required this.totalCustomerDue,
    required this.totalDistributorDue,
  });

  factory DuesReport.fromJson(Map<String, dynamic> json) => DuesReport(
    customers: (json['customers'] as List<dynamic>? ?? [])
        .map((e) => DueRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    distributors: (json['distributors'] as List<dynamic>? ?? [])
        .map((e) => DueRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalCustomerDue: _toDouble(json['total_customer_due']),
    totalDistributorDue: _toDouble(json['total_distributor_due']),
  );

  final List<DueRow> customers;
  final List<DueRow> distributors;
  final double totalCustomerDue;
  final double totalDistributorDue;
}

class ImeiHistoryMovement {
  const ImeiHistoryMovement({
    required this.date,
    required this.type,
    required this.branch,
    required this.quantityChange,
    this.unitCost,
    this.saleDate,
    this.saleInvoiceNumber,
    this.saleCustomer,
    this.saleUnitPrice,
    this.saleDiscount,
    this.saleTotal,
  });

  factory ImeiHistoryMovement.fromJson(Map<String, dynamic> json) =>
      ImeiHistoryMovement(
        date: json['date'] as String,
        type: json['type'] as String,
        branch: json['branch'] as String,
        quantityChange: json['quantity_change'] as int,
        unitCost: _toDoubleOrNull(json['unit_cost']),
        saleDate: json['sale_date'] as String?,
        saleInvoiceNumber: json['sale_invoice_number'] as String?,
        saleCustomer: json['sale_customer'] as String?,
        saleUnitPrice: _toDoubleOrNull(json['sale_unit_price']),
        saleDiscount: _toDoubleOrNull(json['sale_discount']),
        saleTotal: _toDoubleOrNull(json['sale_total']),
      );

  final String date;
  final String type;
  final String branch;
  final int quantityChange;
  final double? unitCost;
  final String? saleDate;
  final String? saleInvoiceNumber;
  final String? saleCustomer;
  final double? saleUnitPrice;
  final double? saleDiscount;
  final double? saleTotal;
}

class ImeiHistory {
  const ImeiHistory({
    required this.unitId,
    required this.imei1,
    required this.imei2,
    required this.status,
    required this.displayName,
    required this.distributor,
    required this.isDemo,
    required this.movements,
    this.purchasedAt,
    this.soldAt,
    this.purchaseCost,
  });

  factory ImeiHistory.fromJson(Map<String, dynamic> json) {
    final unit = json['unit'] as Map<String, dynamic>;
    return ImeiHistory(
      unitId: unit['id'] as int,
      imei1: unit['imei1'] as String,
      imei2: unit['imei2'] as String?,
      status: unit['status'] as String,
      displayName: unit['display_name'] as String,
      distributor: unit['distributor'] as String,
      isDemo: unit['is_demo'] as bool? ?? false,
      purchasedAt: unit['purchased_at'] as String?,
      soldAt: unit['sold_at'] as String?,
      purchaseCost: _toDoubleOrNull(unit['purchase_cost']),
      movements: (json['movements'] as List<dynamic>? ?? [])
          .map((e) => ImeiHistoryMovement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int unitId;
  final String imei1;
  final String? imei2;
  final String status;
  final String displayName;
  final String distributor;
  final bool isDemo;
  final String? purchasedAt;
  final String? soldAt;
  final double? purchaseCost;
  final List<ImeiHistoryMovement> movements;
}

class StockMovementHistory {
  const StockMovementHistory({
    required this.skuId,
    required this.displayName,
    required this.movements,
  });

  factory StockMovementHistory.fromJson(Map<String, dynamic> json) {
    final sku = json['sku'] as Map<String, dynamic>;
    return StockMovementHistory(
      skuId: sku['id'] as int,
      displayName: sku['display_name'] as String,
      movements: (json['movements'] as List<dynamic>? ?? [])
          .map((e) => ImeiHistoryMovement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final int skuId;
  final String displayName;
  final List<ImeiHistoryMovement> movements;
}

class CashPositionRow {
  const CashPositionRow({
    required this.method,
    required this.accountCode,
    required this.balance,
  });

  factory CashPositionRow.fromJson(Map<String, dynamic> json) =>
      CashPositionRow(
        method: json['method'] as String,
        accountCode: json['account_code'] as String,
        balance: _toDouble(json['balance']),
      );

  final String method;
  final String accountCode;
  final double balance;
}
