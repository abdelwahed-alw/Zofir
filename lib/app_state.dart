import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'l10n/strings.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  static const _boxName = 'expense_box';
  late Box _box;

  List<AppUser> _users = [];
  List<Expense> _expenses = [];
  List<Settlement> _settlements = [];
  bool _loaded = false;

  // --- Theme & Locale (persisted) ---
  ThemeMode _themeMode = ThemeMode.light;
  String _localeCode = 'en'; // 'en' | 'ar'

  List<AppUser> get users => _users;
  List<Expense> get expenses =>
      [..._expenses]..sort((a, b) => b.date.compareTo(a.date));
  List<Settlement> get settlements => _settlements;
  bool get loaded => _loaded;
  bool get hasUsers => _users.isNotEmpty;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  String get localeCode => _localeCode;
  bool get isArabic => _localeCode == 'ar';

  /// Simple dictionary lookup with optional {name} replacement.
  String tr(String key, {Map<String, String>? params}) {
    var s = AppStrings.get(_localeCode, key);
    params?.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  String userName(String id) => _users
      .firstWhere((u) => u.id == id,
          orElse: () => AppUser(id: id, name: 'Unknown', pin: ''))
      .name;

  String userPin(String id) => _users
      .firstWhere((u) => u.id == id,
          orElse: () => AppUser(id: id, name: 'Unknown', pin: ''))
      .pin;

  /// Receiver confirmation: entered PIN must match receiver's stored PIN.
  /// Legacy users with empty PIN are treated as "no PIN required".
  bool verifyReceiverPin(String receiverId, String enteredPin) {
    final stored = userPin(receiverId);
    if (stored.isEmpty) return true;
    return stored == enteredPin.trim();
  }

  Future<void> init() async {
    _box = Hive.box(_boxName);
    final u = _box.get('users', defaultValue: <dynamic>[]);
    final e = _box.get('expenses', defaultValue: <dynamic>[]);
    final s = _box.get('settlements', defaultValue: <dynamic>[]);
    _users = (u as List)
        .map((m) => AppUser.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    _expenses = (e as List)
        .map((m) => Expense.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    _settlements = (s as List)
        .map((m) => Settlement.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
    final tm = _box.get('themeMode', defaultValue: 'light') as String;
    _themeMode = tm == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _localeCode = _box.get('locale', defaultValue: 'en') as String;
    if (_localeCode != 'ar') _localeCode = 'en';
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _box.put('users', _users.map((x) => x.toMap()).toList());
    await _box.put('expenses', _expenses.map((x) => x.toMap()).toList());
    await _box.put(
        'settlements', _settlements.map((x) => x.toMap()).toList());
    await _box.put('themeMode', isDark ? 'dark' : 'light');
    await _box.put('locale', _localeCode);
  }

  Future<void> toggleTheme() async {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    _localeCode = isArabic ? 'en' : 'ar';
    await _persist();
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    if (code != 'en' && code != 'ar') return;
    _localeCode = code;
    await _persist();
    notifyListeners();
  }

  /// New API with PINs. `pins` must be 4-digit strings, same length as names.
  Future<void> setUsers(List<String> names, List<String> pins) async {
    assert(names.length == pins.length);
    const uuid = Uuid();
    _users = List.generate(
      names.length,
      (i) => AppUser(
          id: uuid.v4(), name: names[i].trim(), pin: pins[i].trim()),
    );
    _expenses = [];
    _settlements = [];
    await _persist();
    notifyListeners();
  }

  Future<void> addExpense({
    required String description,
    required double amount,
    required String paidById,
    required List<String> participantIds,
  }) async {
    final exp = Expense(
      id: const Uuid().v4(),
      description: description.trim(),
      amount: amount,
      paidById: paidById,
      participantIds: participantIds,
      date: DateTime.now(),
    );
    _expenses.add(exp);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _persist();
    notifyListeners();
  }

  /// Settle Up: debtor pays creditor -> zeroes that edge.
  /// Caller MUST verify receiver PIN first via [verifyReceiverPin].
  Future<void> settleDebt(String fromId, String toId, double amount) async {
    final st = Settlement(
      id: const Uuid().v4(),
      fromId: fromId,
      toId: toId,
      amount: amount,
      date: DateTime.now(),
    );
    _settlements.add(st);
    await _persist();
    notifyListeners();
  }

  Future<void> resetAll() async {
    _users = [];
    _expenses = [];
    _settlements = [];
    // Keep theme/locale across reset for better UX.
    await _box.delete('users');
    await _box.delete('expenses');
    await _box.delete('settlements');
    notifyListeners();
  }

  double get totalSpent => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// CORE LOGIC: net balance per user
  /// + means owed money, - means owes money
  Map<String, double> getBalances() {
    final Map<String, double> bal = {for (var u in _users) u.id: 0.0};

    for (var e in _expenses) {
      if (!bal.containsKey(e.paidById)) continue;
      bal[e.paidById] = bal[e.paidById]! + e.amount;
      if (e.participantIds.isEmpty) continue;
      final share = e.amount / e.participantIds.length;
      for (var pid in e.participantIds) {
        if (bal.containsKey(pid)) bal[pid] = bal[pid]! - share;
      }
    }
    // Settlements offset net: payer +amount, receiver -amount
    for (var s in _settlements) {
      if (bal.containsKey(s.fromId)) bal[s.fromId] = bal[s.fromId]! + s.amount;
      if (bal.containsKey(s.toId)) bal[s.toId] = bal[s.toId]! - s.amount;
    }
    return bal;
  }

  /// Greedy creditor/debtor matching
  List<Debt> getSimplifiedDebts() {
    final bal = getBalances();
    const eps = 0.01;
    final creditors = bal.entries.where((e) => e.value > eps).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final debtors = bal.entries.where((e) => e.value < -eps).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final List<Debt> out = [];
    int i = 0, j = 0;
    final cAmt = creditors.map((e) => e.value).toList();
    final dAmt = debtors.map((e) => -e.value).toList(); // positive owed

    while (i < debtors.length && j < creditors.length) {
      final pay = cAmt[j] < dAmt[i] ? cAmt[j] : dAmt[i];
      if (pay > eps) {
        out.add(Debt(
            fromId: debtors[i].key,
            toId: creditors[j].key,
            amount: pay));
        cAmt[j] -= pay;
        dAmt[i] -= pay;
      }
      if (cAmt[j] < eps) j++;
      if (dAmt[i] < eps) i++;
    }
    return out;
  }
}
