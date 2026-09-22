class LedgerAccount {
  const LedgerAccount({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.isSystem,
    required this.balance,
  });

  factory LedgerAccount.fromJson(Map<String, dynamic> json) => LedgerAccount(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        isSystem: json['is_system'] as bool,
        balance: (json['balance'] as num).toDouble(),
      );

  final int id;
  final String code;
  final String name;
  final String type;
  final bool isSystem;
  final double balance;
}

class LedgerLine {
  const LedgerLine({
    required this.id,
    required this.date,
    required this.narration,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.account,
  });

  factory LedgerLine.fromJson(Map<String, dynamic> json) => LedgerLine(
        id: json['id'] as int,
        date: json['date'] as String,
        narration: json['narration'] as String,
        debit: (json['debit'] as num).toDouble(),
        credit: (json['credit'] as num).toDouble(),
        runningBalance: (json['running_balance'] as num).toDouble(),
        account: json['account'] as String?,
      );

  final int id;
  final String date;
  final String narration;
  final double debit;
  final double credit;
  final double runningBalance;
  final String? account;
}
