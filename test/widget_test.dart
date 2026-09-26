import 'package:flutter_test/flutter_test.dart';
import 'package:zofir/l10n/strings.dart';
import 'package:zofir/models.dart';

void main() {
  test('Net balance offsets automatically (Amin example)', () {
    // Amin pays 20 split by 2 -> B owes Amin 10
    // Then B pays 20 split by 2 -> net 0
    const amin = 'amin';
    const b = 'b';

    Map<String, double> bal = {amin: 0.0, b: 0.0};

    void applyExpense(String paidBy, double amount, List<String> parts) {
      bal[paidBy] = bal[paidBy]! + amount;
      final share = amount / parts.length;
      for (var p in parts) {
        bal[p] = bal[p]! - share;
      }
    }

    applyExpense(amin, 20, [amin, b]);
    expect(bal[amin], 10.0);
    expect(bal[b], -10.0);

    applyExpense(b, 20, [amin, b]);
    expect(bal[amin]!.abs(), lessThan(0.01));
    expect(bal[b]!.abs(), lessThan(0.01));
  });

  test('Models serialize correctly', () {
    final e = Expense(
      id: '1',
      description: 'Potatoes',
      amount: 20,
      paidById: 'u1',
      participantIds: ['u1', 'u2'],
      date: DateTime(2026, 1, 1),
    );
    final rt = Expense.fromMap(e.toMap());
    expect(rt.description, 'Potatoes');
    expect(rt.amount, 20);
    expect(rt.participantIds.length, 2);
  });

  test('AppUser PIN round-trips + legacy compat', () {
    final u = AppUser(id: 'x', name: 'Amin', pin: '1234');
    final rt = AppUser.fromMap(u.toMap());
    expect(rt.pin, '1234');
    // Old installs without PIN default to empty (no PIN required)
    final legacy = AppUser.fromMap({'id': 'y', 'name': 'Bob'});
    expect(legacy.pin, '');
  });

  test('Localization EN/AR present + RTL strings differ', () {
    expect(AppStrings.get('en', 'settleUp'), 'Settle Up');
    expect(AppStrings.get('ar', 'settleUp'), isNot('Settle Up'));
    expect(AppStrings.get('ar', 'settleUp'), 'تسوية');
    expect(AppStrings.get('en', 'wrongPin'), isNotEmpty);
    expect(AppStrings.get('ar', 'wrongPin'), isNotEmpty);
  });
}
