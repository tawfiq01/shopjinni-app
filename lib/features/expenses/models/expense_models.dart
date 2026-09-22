class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.isActive,
    required this.accountCode,
    required this.totalSpent,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => ExpenseCategory(
        id: json['id'] as int,
        name: json['name'] as String,
        isActive: json['is_active'] as bool,
        accountCode: json['account_code'] as String,
        totalSpent: (json['total_spent'] as num).toDouble(),
      );

  final int id;
  final String name;
  final bool isActive;
  final String accountCode;
  final double totalSpent;
}

class Expense {
  const Expense({
    required this.id,
    required this.date,
    required this.amount,
    required this.categoryName,
    required this.paymentAccountName,
    this.description,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as int,
        date: json['date'] as String,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String?,
        categoryName: json['category']['name'] as String,
        paymentAccountName: json['payment_account']['name'] as String,
      );

  final int id;
  final String date;
  final double amount;
  final String? description;
  final String categoryName;
  final String paymentAccountName;
}
