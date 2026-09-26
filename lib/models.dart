class AppUser {
  final String id;
  final String name;
  final String pin; // 4-digit receiver-confirmation PIN (plaintext, demo)
  AppUser({required this.id, required this.name, required this.pin});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'pin': pin};
  factory AppUser.fromMap(Map m) => AppUser(
        id: m['id'] as String,
        name: m['name'] as String,
        // Backwards compat: old installs have no PIN -> empty (no PIN required)
        pin: (m['pin'] as String?) ?? '',
      );
}

class Expense {
  final String id;
  final String description;
  final double amount;
  final String paidById;
  final List<String> participantIds;
  final DateTime date;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidById,
    required this.participantIds,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'amount': amount,
        'paidById': paidById,
        'participantIds': participantIds,
        'date': date.toIso8601String(),
      };

  factory Expense.fromMap(Map m) => Expense(
        id: m['id'] as String,
        description: m['description'] as String,
        amount: (m['amount'] as num).toDouble(),
        paidById: m['paidById'] as String,
        participantIds: List<String>.from(m['participantIds'] as List),
        date: DateTime.parse(m['date'] as String),
      );
}

class Settlement {
  final String id;
  final String fromId; // debtor who pays
  final String toId; // creditor who receives
  final double amount;
  final DateTime date;

  Settlement({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fromId': fromId,
        'toId': toId,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Settlement.fromMap(Map m) => Settlement(
        id: m['id'] as String,
        fromId: m['fromId'] as String,
        toId: m['toId'] as String,
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.parse(m['date'] as String),
      );
}

/// Simplified debt for UI: from owes to amount
class Debt {
  final String fromId;
  final String toId;
  final double amount;
  Debt({required this.fromId, required this.toId, required this.amount});
}
