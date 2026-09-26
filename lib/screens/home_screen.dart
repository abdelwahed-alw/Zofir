import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../widgets/app_bar_actions.dart';
import '../../widgets/zofir_logo.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String fmt(double v) => '${v.abs().toStringAsFixed(2)} MAD';

  /// Receiver-confirmed settle: asks for RECEIVER's PIN.
  /// E.g. Abbdellwahed owes Amin -> dialog asks for Amin's PIN.
  void _confirmSettle(
      BuildContext context, String fromId, String toId, double amount) {
    final state = context.read<AppState>();
    final receiverName = state.userName(toId);
    final pinCtrl = TextEditingController();
    String? error;

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (ctx, setDlg) => AlertDialog(
                title: Text(
                    '${state.userName(fromId)} → $receiverName\n${fmt(amount)}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(state.tr('settleExplain',
                        params: {'name': receiverName})),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinCtrl,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: state.tr('receiverPin',
                            params: {'name': receiverName}),
                        hintText: state.tr('pinHint'),
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        counterText: '',
                        errorText: error,
                      ),
                      onSubmitted: (_) => _trySettle(
                          ctx, context, fromId, toId, amount,
                          pinCtrl.text, (e) => setDlg(() => error = e)),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(error!,
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.error)),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(state.tr('cancel'))),
                  FilledButton(
                      onPressed: () => _trySettle(
                          ctx, context, fromId, toId, amount,
                          pinCtrl.text, (e) => setDlg(() => error = e)),
                      child: Text(state.tr('markPaid'))),
                ],
              ),
            ));
  }

  void _trySettle(
      BuildContext dlgCtx,
      BuildContext pageCtx,
      String fromId,
      String toId,
      double amount,
      String enteredPin,
      void Function(String?) setError) {
    final state = pageCtx.read<AppState>();
    if (!state.verifyReceiverPin(toId, enteredPin)) {
      setError(state.tr('wrongPin'));
      return;
    }
    state.settleDebt(fromId, toId, amount);
    Navigator.pop(dlgCtx);
    ScaffoldMessenger.of(pageCtx)
        .showSnackBar(SnackBar(content: Text(state.tr('settledOk'))));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final balances = state.getBalances();
    final debts = state.getSimplifiedDebts();
    final dateFmt = DateFormat('dd MMM, HH:mm');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: ZofirLogo(size: 32, withShadow: false),
        ),
        title: Text(state.tr('appTitle')),
        centerTitle: true,
        actions: [
          const ThemeLangActions(),
          IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: state.tr('reset'),
              onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                        title: Text(state.tr('resetTitle')),
                        content: Text(state.tr('resetMsg')),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(state.tr('cancel'))),
                          FilledButton(
                              onPressed: () {
                                context.read<AppState>().resetAll();
                                Navigator.pop(ctx);
                              },
                              child: Text(state.tr('reset'))),
                        ],
                      ))),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        icon: const Icon(Icons.add),
        label: Text(state.tr('addExpense')),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card.filled(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(state.tr('totalSpent'),
                        style: const TextStyle(fontSize: 16)),
                    Text('${state.totalSpent.toStringAsFixed(2)} MAD',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ])),
        ),
        const SizedBox(height: 12),
        Text(state.tr('balances'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...state.users.map((u) {
          final b = balances[u.id] ?? 0;
          final isOwed = b > 0.01;
          final owes = b < -0.01;
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                  child: Text(u.name.isNotEmpty
                      ? u.name[0].toUpperCase()
                      : '?')),
              title: Text(u.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(owes
                  ? '${state.tr('owes')} ${fmt(b)}'
                  : isOwed
                      ? '${state.tr('getsBack')} ${fmt(b)}'
                      : state.tr('settledUp')),
              trailing: Text('${b >= 0 ? '+' : ''}${b.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: owes
                          ? scheme.error
                          : isOwed
                              ? Colors.green
                              : Colors.grey)),
            ),
          );
        }),
        const SizedBox(height: 12),
        Text(state.tr('whoOwesWhom'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (debts.isEmpty)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(state.tr('allSettled'))
                  ]))),
        ...debts.map((d) => Card(
              child: ListTile(
                leading: Icon(Icons.arrow_right_alt,
                    color: scheme.tertiary),
                title: Text(
                    '${state.userName(d.fromId)} ${state.tr('owesWord')} ${state.userName(d.toId)}'),
                subtitle: Text(fmt(d.amount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                trailing: FilledButton.tonal(
                  onPressed: () =>
                      _confirmSettle(context, d.fromId, d.toId, d.amount),
                  child: Text(state.tr('settleUp')),
                ),
              ),
            )),
        const SizedBox(height: 12),
        Text(state.tr('history'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...state.expenses.map((e) => Card.outlined(
              child: Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                    color: scheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(Icons.delete,
                        color: scheme.onError)),
                onDismissed: (_) =>
                    context.read<AppState>().deleteExpense(e.id),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(
                      '${e.description} — ${e.amount.toStringAsFixed(2)} MAD'),
                  subtitle: Text(
                      '${state.userName(e.paidById)} ${state.tr('paid')} • ${dateFmt.format(e.date)}\n${state.tr('split')}: ${e.participantIds.map(state.userName).join(', ')}'),
                  isThreeLine: true,
                ),
              ),
            )),
        ...state.settlements.reversed.map((s) => Card.outlined(
              child: ListTile(
                leading:
                    const Icon(Icons.handshake, color: Colors.green),
                title: Text(
                    '${state.userName(s.fromId)} ${state.tr('paid')} ${state.userName(s.toId)} ${s.amount.toStringAsFixed(2)} MAD'),
                subtitle: Text(
                    '${state.tr('settlement')} • ${dateFmt.format(s.date)}'),
              ),
            )),
        const SizedBox(height: 80),
      ]),
    );
  }
}
