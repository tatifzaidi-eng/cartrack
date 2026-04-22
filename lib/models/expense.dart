import 'package:uuid/uuid.dart';

enum ExpenseType {
  carburant,
  entretien,
  reparation,
  assurance,
  autre,
}

extension ExpenseTypeExtension on ExpenseType {
  String get label {
    switch (this) {
      case ExpenseType.carburant:
        return 'Carburant';
      case ExpenseType.entretien:
        return 'Entretien';
      case ExpenseType.reparation:
        return 'Réparation';
      case ExpenseType.assurance:
        return 'Assurance';
      case ExpenseType.autre:
        return 'Autre';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseType.carburant:
        return '⛽';
      case ExpenseType.entretien:
        return '🔧';
      case ExpenseType.reparation:
        return '🔨';
      case ExpenseType.assurance:
        return '🛡️';
      case ExpenseType.autre:
        return '📌';
    }
  }
}

class Expense {
  final String id;
  final ExpenseType type;
  final double amount;
  final DateTime date;
  final String? note;

  Expense({
    String? id,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        type: ExpenseType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ExpenseType.autre,
        ),
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        note: json['note'],
      );
}
