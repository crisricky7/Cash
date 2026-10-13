import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ProviderScope(child: CashApp()));
}

class AuthSession {
  final String fullName;
  final String email;
  final String role;
  AuthSession({required this.fullName, required this.email, required this.role});
}

class TxItem {
  final String description;
  final double amount;
  final int type; // 1 = Ingreso, 2 = Gasto
  final String categoryName;
  final String accountName;
  final String memberName;
  TxItem({required this.description, required this.amount, required this.type, required this.categoryName, required this.accountName, required this.memberName});
}

final authSessionProvider = StateProvider<AuthSession?>((ref) => null);
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);

final transactionsListProvider = StateProvider<List<TxItem>>((ref) => [
  TxItem(description: 'Compra Quincenal Supermercado', amount: 145.00, type: 2, categoryName: 'Supermercado y Alimentación', accountName: 'Cuenta Bancaria Principal', memberName: 'Admin Hogar'),
  TxItem(description: 'Pago Fibra Óptica + Energía', amount: 85.00, type: 2, categoryName: 'Servicios Básicos (Luz/Agua/Net)', accountName: 'Cuenta Bancaria Principal', memberName: 'Pareja'),
  TxItem(description: 'Ingreso Mensual Hogar', amount: 2500.00, type: 1, categoryName: 'Ingresos / Salario', accountName: 'Cuenta Bancaria Principal', memberName: 'Admin Hogar'),
  TxItem(description: 'Materiales y Colación', amount: 35.00, type: 2, categoryName: 'Educación y Hogar', accountName: 'Efectivo Hogar', memberName: 'Familiar'),
]);

class CashApp extends ConsumerWidget {
  const CashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    return MaterialApp(
      title: 'Cash · Hogar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: session == null ? const LoginScreen() : const DashboardScreen(),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@hogar.com');
  final _passCtrl = TextEditingController(text: 'Password123!');

  void _login(String name, String email, String role) {
    ref.read(authSessionProvider.notifier).state = AuthSession(fullName: name, email: email, role: role);
  }

  @override
  Widget build(BuildContext context) {
    final demoUsers = [
      ('Admin Hogar', 'admin@hogar.com', 'Admin'),
      ('Pareja', 'pareja@hogar.com', 'Miembro'),
      ('Familiar', 'familiar@hogar.com', 'Miembro'),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.attach_money, size: 42, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            const Text('Cash · Hogar', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text('Control de gastos familiar multi-usuario (JWT)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: Colors.grey.shade300)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Iniciar Sesión', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () => _login('Admin Hogar', _emailCtrl.text, 'Admin'),
                      child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Entrar al Hogar')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Cuentas Semilla Pre-cargadas (Acceso Rápido 1-Tap):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...demoUsers.map((u) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text(u.$1[0])),
                title: Text(u.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${u.$2} • Rol: ${u.$3}'),
                trailing: const Icon(Icons.login),
                onTap: () => _login(u.$1, u.$2, u.$3),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final selectedMember = ref.watch(selectedMemberFilterProvider);
    final allTx = ref.watch(transactionsListProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final income = allTx.where((t) => t.type == 1).fold(0.0, (s, t) => s + t.amount);
    final expense = allTx.where((t) => t.type == 2).fold(0.0, (s, t) => s + t.amount);
    final totalBalance = income - expense;

    final members = allTx.where((t) => t.type == 2).map((t) => t.memberName).toSet().toList();
    final filteredTx = selectedMember == null ? allTx : allTx.where((t) => t.memberName == selectedMember).toList();

    final budgets = [
      ('Supermercado y Alimentación', 600.0),
      ('Servicios Básicos (Luz/Agua/Net)', 180.0),
      ('Educación y Hogar', 350.0),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cash · Finanzas del Hogar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Conectado: ${session?.fullName} (JWT Activo)', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(authSessionProvider.notifier).state = null,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Salir'),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saldo Total del Hogar', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(currency.format(totalBalance), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('▲ Ingresos: ${currency.format(income)}', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                      Text('▼ Gastos: ${currency.format(expense)}', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Gastos por Miembro (Filtro Interactivo)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text('Todos: ${currency.format(expense)}'),
                selected: selectedMember == null,
                onSelected: (_) => ref.read(selectedMemberFilterProvider.notifier).state = null,
              ),
              ...members.map((m) {
                final mSpent = allTx.where((t) => t.type == 2 && t.memberName == m).fold(0.0, (s, t) => s + t.amount);
                return ChoiceChip(
                  label: Text('$m: ${currency.format(mSpent)}'),
                  selected: selectedMember == m,
                  onSelected: (_) => ref.read(selectedMemberFilterProvider.notifier).state = m,
                );
              }),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Presupuestos Mensuales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...budgets.map((b) {
            final spent = allTx.where((t) => t.type == 2 && t.categoryName == b.$1).fold(0.0, (s, t) => s + t.amount);
            final progress = (spent / b.$2).clamp(0.0, 1.0);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(b.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: progress, color: progress > 0.85 ? Colors.red : null),
                    const SizedBox(height: 4),
                    Text('${currency.format(spent)} gastados de ${currency.format(b.$2)}'),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text('Movimientos Recientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...filteredTx.map((t) {
            final isInc = t.type == 1;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isInc ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(isInc ? Icons.arrow_downward : Icons.arrow_upward, color: isInc ? Colors.green.shade800 : Colors.red.shade800),
                ),
                title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${t.categoryName} • Por: ${t.memberName}'),
                trailing: Text('${isInc ? '+' : '-'}${currency.format(t.amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: isInc ? Colors.green.shade700 : Colors.red.shade700)),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const NewTxModal()),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
    );
  }
}

class NewTxModal extends ConsumerStatefulWidget {
  const NewTxModal({super.key});
  @override
  ConsumerState<NewTxModal> createState() => _NewTxModalState();
}

class _NewTxModalState extends ConsumerState<NewTxModal> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _type = 2;
  String _category = 'Supermercado y Alimentación';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final categories = _type == 2
        ? ['Supermercado y Alimentación', 'Servicios Básicos (Luz/Agua/Net)', 'Educación y Hogar']
        : ['Ingresos / Salario'];
    if (!categories.contains(_category)) _category = categories.first;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nuevo Movimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
            child: Text('✓ Autor asignado vía Token JWT: ${session?.fullName ?? "Hogar"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 2, label: Text('Gasto'), icon: Icon(Icons.remove_circle_outline)),
              ButtonSegment(value: 1, label: Text('Ingreso'), icon: Icon(Icons.add_circle_outline)),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          const SizedBox(height: 12),
          TextField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monto (USD)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final amt = double.tryParse(_amountCtrl.text) ?? 0;
              if (amt <= 0) return;
              final list = ref.read(transactionsListProvider);
              ref.read(transactionsListProvider.notifier).state = [
                TxItem(
                  description: _descCtrl.text.isEmpty ? 'Movimiento' : _descCtrl.text,
                  amount: amt,
                  type: _type,
                  categoryName: _category,
                  accountName: 'Cuenta Bancaria Principal',
                  memberName: session?.fullName ?? 'Hogar',
                ),
                ...list,
              ];
              Navigator.pop(context);
            },
            child: const Text('Guardar Movimiento'),
          ),
        ],
      ),
    );
  }
}
