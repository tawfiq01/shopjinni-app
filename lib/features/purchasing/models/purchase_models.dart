class PaymentMethodOption {
  const PaymentMethodOption({required this.id, required this.name});

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) =>
      PaymentMethodOption(id: json['id'] as int, name: json['name'] as String);

  final int id;
  final String name;
}

class PurchasedImeiUnit {
  const PurchasedImeiUnit({
    required this.id,
    required this.imei1,
    required this.status,
    required this.isDemo,
  });

  factory PurchasedImeiUnit.fromJson(Map<String, dynamic> json) => PurchasedImeiUnit(
        id: json['id'] as int,
        imei1: json['imei1'] as String,
        status: json['status'] as String,
        isDemo: json['is_demo'] as bool? ?? false,
      );

  final int id;
  final String imei1;
  final String status;
  final bool isDemo;

  bool get isInStock => status == 'in_stock';
}

class PurchaseItemSummary {
  const PurchaseItemSummary({
    required this.id,
    required this.sku,
    required this.displayName,
    required this.quantity,
    required this.remainingQuantity,
    required this.unitCost,
    required this.lineTotal,
    required this.imeis,
  });

  factory PurchaseItemSummary.fromJson(Map<String, dynamic> json) => PurchaseItemSummary(
        id: json['id'] as int,
        sku: json['sku'] as String,
        displayName: json['display_name'] as String,
        quantity: json['quantity'] as int,
        remainingQuantity: json['remaining_quantity'] as int,
        unitCost: (json['unit_cost'] as num).toDouble(),
        lineTotal: (json['line_total'] as num).toDouble(),
        imeis: (json['imeis'] as List<dynamic>? ?? [])
            .map((e) => PurchasedImeiUnit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String sku;
  final String displayName;
  final int quantity;
  final int remainingQuantity;
  final double unitCost;
  final double lineTotal;
  final List<PurchasedImeiUnit> imeis;

  bool get isImeiTracked => imeis.isNotEmpty;
}

class PurchasePaymentSummary {
  const PurchasePaymentSummary({
    required this.id,
    required this.method,
    required this.amount,
    required this.paidAt,
  });

  factory PurchasePaymentSummary.fromJson(Map<String, dynamic> json) => PurchasePaymentSummary(
        id: json['id'] as int,
        method: json['method'] as String,
        amount: (json['amount'] as num).toDouble(),
        paidAt: json['paid_at'] as String,
      );

  final int id;
  final String method;
  final double amount;
  final String paidAt;
}

class PurchaseInvoice {
  const PurchaseInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.purchaseDate,
    required this.distributorName,
    required this.total,
    required this.paidAmount,
    required this.dueAmount,
    required this.items,
    required this.payments,
  });

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) => PurchaseInvoice(
        id: json['id'] as int,
        invoiceNumber: json['invoice_number'] as String,
        purchaseDate: json['purchase_date'] as String,
        distributorName: json['distributor']['name'] as String,
        total: (json['total'] as num).toDouble(),
        paidAmount: (json['paid_amount'] as num).toDouble(),
        dueAmount: (json['due_amount'] as num).toDouble(),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => PurchaseItemSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        payments: (json['payments'] as List<dynamic>? ?? [])
            .map((e) => PurchasePaymentSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String invoiceNumber;
  final String purchaseDate;
  final String distributorName;
  final double total;
  final double paidAmount;
  final double dueAmount;
  final List<PurchaseItemSummary> items;
  final List<PurchasePaymentSummary> payments;
}
