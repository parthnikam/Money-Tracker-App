/// Domain entity for a money movement (income or expense).
enum TransactionType { income, expense }

class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.cardId,
    required this.date,
    this.note,
    this.paymentMethod,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final String cardId;
  final DateTime date;
  final String? note;
  final String? paymentMethod;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? cardId,
    DateTime? date,
    String? note,
    bool clearNote = false,
    String? paymentMethod,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      cardId: cardId ?? this.cardId,
      date: date ?? this.date,
      note: clearNote ? null : (note ?? this.note),
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'cardId': cardId,
        'date': date.toIso8601String(),
        'note': note,
        'paymentMethod': paymentMethod,
      };

  factory Transaction.fromMap(Map<dynamic, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.byName(map['type'] as String),
      categoryId: map['categoryId'] as String,
      cardId: map['cardId'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
    );
  }
}
