import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../widgets/app_bar_actions.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _paidById;
  late Set<String> _involved;
  bool _initDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initDone) {
      final users = context.read<AppState>().users;
      _paidById = users.first.id;
      _involved = users.map((u) => u.id).toSet(); // default everyone
      _initDone = true;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final state = context.read<AppState>();
    if (!_formKey.currentState!.validate()) return;
    if (_involved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.tr('selectOne'))));
      return;
    }
    state.addExpense(
      description: _descCtrl.text,
      amount: double.parse(_amountCtrl.text),
      paidById: _paidById!,
      participantIds: _involved.toList(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(state.tr('addExpenseTitle')),
        actions: const [ThemeLangActions()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _descCtrl,
            decoration: InputDecoration(
                labelText: state.tr('description'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.receipt)),
            validator: (v) => v == null || v.trim().isEmpty
                ? state.tr('descriptionError')
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: state.tr('amount'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.money)),
            validator: (v) {
              final d = double.tryParse(v ?? '');
              if (d == null || d <= 0) return state.tr('amountError');
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _paidById,
            decoration: InputDecoration(
                labelText: state.tr('whoPaid'),
                border: const OutlineInputBorder()),
            items: state.users
                .map((u) =>
                    DropdownMenuItem(value: u.id, child: Text(u.name)))
                .toList(),
            onChanged: (v) => setState(() => _paidById = v),
          ),
          const SizedBox(height: 16),
          Text(state.tr('splitAmong'),
              style: Theme.of(context).textTheme.titleMedium),
          ...state.users.map((u) => CheckboxListTile(
                value: _involved.contains(u.id),
                title: Text(u.name),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _involved.add(u.id);
                  } else {
                    _involved.remove(u.id);
                  }
                }),
              )),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(state.tr('save'))),
        ]),
      ),
    );
  }
}
