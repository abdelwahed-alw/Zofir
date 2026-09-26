import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../widgets/app_bar_actions.dart';
import '../../widgets/zofir_logo.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int count = 2;
  late List<TextEditingController> nameControllers;
  late List<TextEditingController> pinControllers;

  static final _pinFormatter = FilteringTextInputFormatter.digitsOnly;

  @override
  void initState() {
    super.initState();
    nameControllers = List.generate(6, (_) => TextEditingController());
    pinControllers = List.generate(6, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var c in nameControllers) {
      c.dispose();
    }
    for (var c in pinControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isValidPin(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);

  void _save() {
    final state = context.read<AppState>();
    final names =
        nameControllers.take(count).map((c) => c.text.trim()).toList();
    final pins =
        pinControllers.take(count).map((c) => c.text.trim()).toList();
    if (names.any((n) => n.isEmpty) || pins.any((p) => p.isEmpty)) {
      _msg(state.tr('fillAll'));
      return;
    }
    if (names.toSet().length != names.length) {
      _msg(state.tr('unique'));
      return;
    }
    if (pins.any((p) => !_isValidPin(p))) {
      _msg(state.tr('pinInvalid'));
      return;
    }
    state.setUsers(names, pins);
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(state.tr('setupTitle')),
        centerTitle: true,
        actions: const [ThemeLangActions()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: ZofirLogo(size: 88)),
            const SizedBox(height: 12),
            Text('Zofir',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(state.tr('whoSharing'),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                    onPressed:
                        count > 2 ? () => setState(() => count--) : null,
                    icon: const Icon(Icons.remove)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$count ${state.tr('people')}',
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton.filledTonal(
                    onPressed:
                        count < 6 ? () => setState(() => count++) : null,
                    icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(
                count,
                (i) => Card.outlined(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextField(
                              controller: nameControllers[i],
                              decoration: InputDecoration(
                                labelText:
                                    '${state.tr('person')} ${i + 1} ${state.tr('nameLabel')}',
                                prefixIcon: const Icon(Icons.person),
                                border: const OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: pinControllers[i],
                              decoration: InputDecoration(
                                labelText: state.tr('pinLabel'),
                                prefixIcon: const Icon(Icons.lock),
                                border: const OutlineInputBorder(),
                                hintText: '1234',
                                counterText: '',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [_pinFormatter],
                              maxLength: 4,
                              obscureText: true,
                            ),
                          ],
                        ),
                      ),
                    )),
            const SizedBox(height: 8),
            FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(state.tr('start'))),
          ],
        ),
      ),
    );
  }
}
