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
  final DateTime date;
  TxItem({
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryName,
    required this.accountName,
    required this.memberName,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}

final authSessionProvider = StateProvider<AuthSession?>((ref) => null);
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);
final navIndexProvider = StateProvider<int>((ref) => 0);

final transactionsListProvider = StateProvider<List<TxItem>>((ref) => [
  TxItem(
    description: 'Compra Quincenal Supermercado',
    amount: 145.00,
    type: 2,
    categoryName: 'Supermercado y Alimentación',
    accountName: 'Cuenta Bancaria Principal',
    memberName: 'Admin Hogar',
  ),
  TxItem(
    description: 'Pago Fibra Óptica + Energía',
    amount: 85.00,
    type: 2,
    categoryName: 'Servicios Básicos (Luz/Agua/Net)',
    accountName: 'Cuenta Bancaria Principal',
    memberName: 'Pareja',
  ),
  TxItem(
    description: 'Ingreso Mensual Hogar',
    amount: 2500.00,
    type: 1,
    categoryName: 'Ingresos / Salario',
    accountName: 'Cuenta Bancaria Principal',
    memberName: 'Admin Hogar',
  ),
  TxItem(
    description: 'Materiales y Colación Escolar',
    amount: 35.00,
    type: 2,
    categoryName: 'Educación y Hogar',
    accountName: 'Efectivo Hogar',
    memberName: 'Familiar',
  ),
]);

class CashApp extends ConsumerWidget {
  const CashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    return MaterialApp(
      title: 'Cash · Finanzas del Hogar (Web & Móvil)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: session == null ? const LoginScreen() : const ResponsiveHomeShell(),
    );
  }
}

// ============================================================================
// PANTALLA DE LOGIN ADAPTATIVA (CENTRADA EN WEB / COMPLETA EN MÓVIL)
// ============================================================================
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@hogar.com');
  final _passCtrl = TextEditingController(text: 'Password123!');

  void _login(String name, String email, String role) {
    ref.read(authSessionProvider.notifier).state =
        AuthSession(fullName: name, email: email, role: role);
  }

  @override
  Widget build(BuildContext context) {
    final demoUsers = [
      ('Admin Hogar', 'admin@hogar.com', 'Admin'),
      ('Pareja', 'pareja@hogar.com', 'Miembro'),
      ('Familiar', 'familiar@hogar.com', 'Miembro'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.account_balance_wallet,
                      size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                const Text('Cash · Hogar',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                const Text('Plataforma Web & Móvil de Control de Gastos (JWT)',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Iniciar Sesión',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => _login('Admin Hogar', _emailCtrl.text, 'Admin'),
                          icon: const Icon(Icons.login),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Entrar al Hogar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Cuentas Semilla Pre-cargadas (Acceso Rápido 1-Clic):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 8),
                ...demoUsers.map((u) => Card(
                      color: Colors.white,
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(u.$1[0])),
                        title: Text(u.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${u.$2} • Rol: ${u.$3}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _login(u.$1, u.$2, u.$3),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SHELL ADAPTATIVO: SIDEBAR + 2 COLUMNAS EN WEB / VISTA COMPACTA EN MÓVIL
// ============================================================================
class ResponsiveHomeShell extends ConsumerWidget {
  const ResponsiveHomeShell({super.key});

  void _openNewTransaction(BuildContext context, bool isWide) {
    if (isWide) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const NewTxModal(),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const NewTxModal(),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final navIdx = ref.watch(navIndexProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: isWide
              ? null
              : AppBar(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cash · Finanzas del Hogar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Conectado: ${session?.fullName} (JWT Activo)',
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.primary)),
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
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  extended: constraints.maxWidth >= 1100,
                  backgroundColor: Colors.white,
                  selectedIndex: navIdx,
                  onDestinationSelected: (i) => ref.read(navIndexProvider.notifier).state = i,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Icon(Icons.attach_money,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer),
                            ),
                            if (constraints.maxWidth >= 1100) ...[
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Cash · Hogar',
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                  Text('${session?.fullName} (${session?.role})',
                                      style: const TextStyle(fontSize: 12, color: Colors.teal)),
                                ],
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => _openNewTransaction(context, true),
                          icon: const Icon(Icons.add),
                          label: Text(
                              constraints.maxWidth >= 1100 ? 'Nuevo Movimiento' : 'Nuevo'),
                        ),
                      ],
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: TextButton.icon(
                          onPressed: () => ref.read(authSessionProvider.notifier).state = null,
                          icon: const Icon(Icons.logout),
                          label: Text(constraints.maxWidth >= 1100 ? 'Cerrar Sesión' : ''),
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Panel Principal'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_balance_outlined),
                      selectedIcon: Icon(Icons.account_balance),
                      label: Text('Cuentas del Hogar'),
                    ),
                  ],
                ),
              if (isWide) const VerticalDivider(width: 1),
              Expanded(
                child: navIdx == 0
                    ? DashboardContent(isWide: isWide)
                    : const AccountsSummaryView(),
              ),
            ],
          ),
          floatingActionButton: isWide
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _openNewTransaction(context, false),
                  icon: const Icon(Icons.add),
                  label: const Text('Registrar'),
                ),
        );
      },
    );
  }
}

// ============================================================================
// CONTENIDO DEL DASHBOARD (2 COLUMNAS EN WEB / 1 COLUMNA EN MÓVIL)
// ============================================================================
class DashboardContent extends ConsumerWidget {
  final bool isWide;
  const DashboardContent({super.key, required this.isWide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMember = ref.watch(selectedMemberFilterProvider);
    final allTx = ref.watch(transactionsListProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final income = allTx.where((t) => t.type == 1).fold(0.0, (s, t) => s + t.amount);
    final expense = allTx.where((t) => t.type == 2).fold(0.0, (s, t) => s + t.amount);
    final totalBalance = income - expense;

    final members = allTx.where((t) => t.type == 2).map((t) => t.memberName).toSet().toList();
    final filteredTx = selectedMember == null
        ? allTx
        : allTx.where((t) => t.memberName == selectedMember).toList();

    final budgets = [
      ('Supermercado y Alimentación', 600.0),
      ('Servicios Básicos (Luz/Agua/Net)', 180.0),
      ('Educación y Hogar', 350.0),
    ];

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo Consolidado del Hogar', style: TextStyle(fontSize: 15)),
                const SizedBox(height: 8),
                Text(currency.format(totalBalance),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('▲ Ingresos: ${currency.format(income)}',
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text('▼ Gastos: ${currency.format(expense)}',
                        style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Presupuestos Mensuales por Categoría',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...budgets.map((b) {
          final spent = allTx
              .where((t) => t.type == 2 && t.categoryName == b.$1)
              .fold(0.0, (s, t) => s + t.amount);
          final progress = (spent / b.$2).clamp(0.0, 1.0);
          final pct = (progress * 100).toInt();
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('$pct%',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: progress > 0.85 ? Colors.red : Colors.teal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: progress > 0.85 ? Colors.red : null,
                  ),
                  const SizedBox(height: 6),
                  Text('${currency.format(spent)} gastados de ${currency.format(b.$2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ),
          );
        }),
      ],
    );

    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Gastos por Miembro (Filtro Interactivo)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('Todos: ${currency.format(expense)}'),
              selected: selectedMember == null,
              onSelected: (_) => ref.read(selectedMemberFilterProvider.notifier).state = null,
            ),
            ...members.map((m) {
              final mSpent = allTx
                  .where((t) => t.type == 2 && t.memberName == m)
                  .fold(0.0, (s, t) => s + t.amount);
              return ChoiceChip(
                label: Text('$m: ${currency.format(mSpent)}'),
                selected: selectedMember == m,
                onSelected: (_) => ref.read(selectedMemberFilterProvider.notifier).state = m,
              );
            }),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Historial de Movimientos Recientes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...filteredTx.map((t) {
          final isInc = t.type == 1;
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isInc ? Colors.green.shade100 : Colors.red.shade100,
                child: Icon(isInc ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isInc ? Colors.green.shade800 : Colors.red.shade800),
              ),
              title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${t.categoryName} • ${t.accountName} • Por: ${t.memberName}'),
              trailing: Text(
                '${isInc ? '+' : '-'}${currency.format(t.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isInc ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
          );
        }),
      ],
    );

    if (isWide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Panel de Control Financiero del Hogar',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const Text('Sincronizado con Arquitectura Limpia .NET 10 + CQRS',
                    style: TextStyle(color: Colors.blueGrey)),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: leftColumn),
                    const SizedBox(width: 28),
                    Expanded(flex: 6, child: rightColumn),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        leftColumn,
        const SizedBox(height: 20),
        rightColumn,
      ],
    );
  }
}

class AccountsSummaryView extends StatelessWidget {
  const AccountsSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cuentas y Billeteras del Hogar',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.teal),
              title: const Text('Cuenta Bancaria Principal',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Moneda: USD • Activa'),
              trailing: const Text('\$1,800.00',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_outlined, color: Colors.teal),
              title:
                  const Text('Efectivo Hogar', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Moneda: USD • Caja Chica'),
              trailing: const Text('\$250.00',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
  String _account = 'Cuenta Bancaria Principal';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final categories = _type == 2
        ? [
            'Supermercado y Alimentación',
            'Servicios Básicos (Luz/Agua/Net)',
            'Educación y Hogar'
          ]
        : ['Ingresos / Salario'];
    if (!categories.contains(_category)) _category = categories.first;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Registrar Movimiento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '✓ Autor asignado vía Token JWT: ${session?.fullName ?? "Hogar"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                  value: 2, label: Text('Gasto'), icon: Icon(Icons.remove_circle_outline)),
              ButtonSegment(
                  value: 1, label: Text('Ingreso'), icon: Icon(Icons.add_circle_outline)),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() => _type = v.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Monto (USD)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration:
                const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _account,
            decoration:
                const InputDecoration(labelText: 'Cuenta', border: OutlineInputBorder()),
            items: ['Cuenta Bancaria Principal', 'Efectivo Hogar']
                .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                .toList(),
            onChanged: (v) => setState(() => _account = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration:
                const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 18),
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
                  accountName: _account,
                  memberName: session?.fullName ?? 'Hogar',
                ),
                ...list,
              ];
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Guardar Movimiento'),
            ),
          ),
        ],
      ),
    );
  }
}
