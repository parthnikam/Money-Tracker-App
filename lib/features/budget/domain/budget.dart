class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.limit,
    required this.month, // first day of month
  });

  final String id;
  final String categoryId;
  final double limit;
  final DateTime month;

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'limit': limit,
        'month': month.toIso8601String(),
      };

  factory Budget.fromMap(Map<dynamic, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String,
      limit: (map['limit'] as num).toDouble(),
      month: DateTime.parse(map['month'] as String),
    );
  }
}

class SavingsPlan {
  const SavingsPlan({
    required this.id,
    required this.title,
    required this.currentAmount,
    required this.targetAmount,
    required this.iconCodePoint,
    required this.colorValue,
  });

  final String id;
  final String title;
  final double currentAmount;
  final double targetAmount;
  final int iconCodePoint;
  final int colorValue;

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'currentAmount': currentAmount,
        'targetAmount': targetAmount,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
      };

  factory SavingsPlan.fromMap(Map<dynamic, dynamic> map) {
    return SavingsPlan(
      id: map['id'] as String,
      title: map['title'] as String,
      currentAmount: (map['currentAmount'] as num).toDouble(),
      targetAmount: (map['targetAmount'] as num).toDouble(),
      iconCodePoint: map['iconCodePoint'] as int,
      colorValue: map['colorValue'] as int,
    );
  }
}
