import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ProviderScope(child: CashApp()));
}

// ============================================================================
// MODELOS DE DOMINIO Y ESTADO REACTIVO (RIVERPOD)
// ============================================================================
class AuthSession {
  final String fullName;
  final String email;
  final String role;
  AuthSession({required this.fullName, required this.email, required this.role});
}

class AccountModel {
  final String id;
  final String name;
  final String type; // Banco, Efectivo, Tarjeta, Ahorro
  final double balance;
  AccountModel({required this.id, required this.name, required this.type, required this.balance});

  AccountModel copyWith({double? balance}) =>
      AccountModel(id: id, name: name, type: type, balance: balance ?? this.balance);
}

class TxItem {
  final String id;
  final String description;
  final double amount;
  final int type; // 1 = Ingreso, 2 = Gasto, 3 = Transferencia
  final String categoryName;
  final String accountName;
  final String memberName;
  final DateTime date;
  TxItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryName,
    required this.accountName,
    required this.memberName,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}

class SavingsGoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String deadline;
  SavingsGoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
  });

  SavingsGoalModel copyWith({double? currentAmount}) => SavingsGoalModel(
        id: id,
        title: title,
        targetAmount: targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline,
      );
}

class RecurringBillModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final int dueDay;
  final bool isPaid;
  RecurringBillModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dueDay,
    this.isPaid = false,
  });

  RecurringBillModel copyWith({bool? isPaid}) => RecurringBillModel(
        id: id,
        title: title,
        category: category,
        amount: amount,
        dueDay: dueDay,
        isPaid: isPaid ?? this.isPaid,
      );
}

// Providers globales
final authSessionProvider = StateProvider<AuthSession?>((ref) => null);
final isDarkModeProvider = StateProvider<bool>((ref) => false);
final isProPlanProvider = StateProvider<bool>((ref) => true); // Activo para demo comercial
final navIndexProvider = StateProvider<int>((ref) => 0);
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final accountsProvider = StateProvider<List<AccountModel>>((ref) => [
      AccountModel(id: '1', name: 'Cuenta Bancaria Principal', type: 'Banco', balance: 1850.00),
      AccountModel(id: '2', name: 'Efectivo Hogar (Caja Chica)', type: 'Efectivo', balance: 280.00),
      AccountModel(id: '3', name: 'Fondo de Reserva Familiar', type: 'Ahorro', balance: 3200.00),
    ]);

final transactionsListProvider = StateProvider<List<TxItem>>((ref) => [
      TxItem(
        id: 't1',
        description: 'Compra Quincenal Supermercado',
        amount: 165.00,
        type: 2,
        categoryName: 'Supermercado y Alimentación',
        accountName: 'Cuenta Bancaria Principal',
        memberName: 'Admin Hogar',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TxItem(
        id: 't2',
        description: 'Pago Fibra Óptica + Energía Eléctrica',
        amount: 92.50,
        type: 2,
        categoryName: 'Servicios Básicos (Luz/Agua/Net)',
        accountName: 'Cuenta Bancaria Principal',
        memberName: 'Pareja',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TxItem(
        id: 't3',
        description: 'Ingreso Salario Mensual Hogar',
        amount: 2800.00,
        type: 1,
        categoryName: 'Ingresos / Salario',
        accountName: 'Cuenta Bancaria Principal',
        memberName: 'Admin Hogar',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      TxItem(
        id: 't4',
        description: 'Útiles, Libros y Colación Escolar',
        amount: 48.00,
        type: 2,
        categoryName: 'Educación y Hogar',
        accountName: 'Efectivo Hogar (Caja Chica)',
        memberName: 'Familiar',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
      TxItem(
        id: 't5',
        description: 'Farmacia y Chequeo Preventivo',
        amount: 64.00,
        type: 2,
        categoryName: 'Salud y Bienestar',
        accountName: 'Cuenta Bancaria Principal',
        memberName: 'Pareja',
        date: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ]);

final savingsGoalsProvider = StateProvider<List<SavingsGoalModel>>((ref) => [
      SavingsGoalModel(
        id: 'g1',
        title: 'Fondo de Emergencia Familiar (6 Meses)',
        targetAmount: 5000.00,
        currentAmount: 3200.00,
        deadline: 'Dic 2026',
      ),
      SavingsGoalModel(
        id: 'g2',
        title: 'Vacaciones Familiares Fin de Año',
        targetAmount: 1800.00,
        currentAmount: 950.00,
        deadline: 'Nov 2026',
      ),
      SavingsGoalModel(
        id: 'g3',
        title: 'Renovación Equipos / Estudio',
        targetAmount: 1200.00,
        currentAmount: 450.00,
        deadline: 'Mar 2027',
      ),
    ]);

final recurringBillsProvider = StateProvider<List<RecurringBillModel>>((ref) => [
      RecurringBillModel(
        id: 'r1',
        title: 'Internet Fibra Óptica Hogar',
        category: 'Servicios Básicos (Luz/Agua/Net)',
        amount: 45.00,
        dueDay: 5,
        isPaid: true,
      ),
      RecurringBillModel(
        id: 'r2',
        title: 'Pensión / Mensualidad Escolar',
        category: 'Educación y Hogar',
        amount: 220.00,
        dueDay: 10,
        isPaid: false,
      ),
      RecurringBillModel(
        id: 'r3',
        title: 'Plan de Energía y Agua Potable',
        category: 'Servicios Básicos (Luz/Agua/Net)',
        amount: 58.00,
        dueDay: 18,
        isPaid: false,
      ),
      RecurringBillModel(
        id: 'r4',
        title: 'Seguro Médico Familiar',
        category: 'Salud y Bienestar',
        amount: 110.00,
        dueDay: 25,
        isPaid: false,
      ),
    ]);

// ============================================================================
// APP PRINCIPAL CON SOPORTE DARK MODE
// ============================================================================
class CashApp extends ConsumerWidget {
  const CashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return MaterialApp(
      title: 'Cash Pro · Finanzas del Hogar',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF14B8A6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: session == null ? const LoginScreen() : const ResponsiveHomeShell(),
    );
  }
}

// ============================================================================
// PANTALLA DE LOGIN MULTI-USUARIO (JWT)
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance_wallet,
                      size: 44, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Cash',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('PRO SaaS',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Plataforma Inteligente de Control de Gastos Familiar',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Acceso con Token JWT',
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
                  child: Text('Perfiles Familiares Pre-cargados (1-Clic Demo):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 8),
                ...demoUsers.map((u) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
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
// SHELL ADAPTATIVO CON 5 MÓDULOS COMERCIALES (WEB SIDEBAR + MÓVIL BOTTOM NAV)
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
            constraints: const BoxConstraints(maxWidth: 500),
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
    final isDark = ref.watch(isDarkModeProvider);
    final isPro = ref.watch(isProPlanProvider);

    final pages = [
      const DashboardView(),
      const AnalyticsAndExportView(),
      const SavingsGoalsView(),
      const RecurringBillsView(),
      const AccountsAndProPlanView(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPro ? Colors.amber.shade700 : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPro ? 'PRO FAMILIAR' : 'PLAN GRATIS',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                if (isWide) ...[
                  const SizedBox(width: 16),
                  Text('•  Sesión JWT: ${session?.fullName} (${session?.role})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
                ]
              ],
            ),
            actions: [
              IconButton(
                tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => ref.read(isDarkModeProvider.notifier).state = !isDark,
              ),
              if (isWide)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilledButton.icon(
                    onPressed: () => _openNewTransaction(context, true),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar Movimiento'),
                  ),
                ),
              IconButton(
                tooltip: 'Cerrar Sesión',
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(authSessionProvider.notifier).state = null,
              ),
            ],
          ),
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  extended: constraints.maxWidth >= 1150,
                  selectedIndex: navIdx,
                  onDestinationSelected: (i) => ref.read(navIndexProvider.notifier).state = i,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard Hogar'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.pie_chart_outline),
                      selectedIcon: Icon(Icons.pie_chart),
                      label: Text('Analítica & Excel CSV'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.savings_outlined),
                      selectedIcon: Icon(Icons.savings),
                      label: Text('Metas de Ahorro'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.event_repeat_outlined),
                      selectedIcon: Icon(Icons.event_repeat),
                      label: Text('Pagos Fijos / Suscrip.'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.workspace_premium_outlined),
                      selectedIcon: Icon(Icons.workspace_premium),
                      label: Text('Cuentas & Cash Pro'),
                    ),
                  ],
                ),
              if (isWide) const VerticalDivider(width: 1),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: pages[navIdx],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: navIdx,
                  onDestinationSelected: (i) => ref.read(navIndexProvider.notifier).state = i,
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.dashboard), label: 'Inicio'),
                    NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Reportes'),
                    NavigationDestination(icon: Icon(Icons.savings), label: 'Metas'),
                    NavigationDestination(icon: Icon(Icons.event_repeat), label: 'Fijos'),
                    NavigationDestination(icon: Icon(Icons.workspace_premium), label: 'Pro'),
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
// PESTAÑA 1: DASHBOARD + SALUD FINANCIERA + BUSCADOR + FILTRO POR MIEMBRO
// ============================================================================
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final allTx = ref.watch(transactionsListProvider);
    final selectedMember = ref.watch(selectedMemberFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final totalBalance = accounts.fold(0.0, (s, a) => s + a.balance);
    final income = allTx.where((t) => t.type == 1).fold(0.0, (s, t) => s + t.amount);
    final expense = allTx.where((t) => t.type == 2).fold(0.0, (s, t) => s + t.amount);
    final savingsRate = income > 0 ? ((income - expense) / income * 100).clamp(0.0, 100.0) : 0.0;
    final healthScore = (savingsRate * 1.4).clamp(45.0, 98.0).toInt();

    final members = allTx.where((t) => t.type == 2).map((t) => t.memberName).toSet().toList();

    final filteredTx = allTx.where((t) {
      final matchesMember = selectedMember == null || t.memberName == selectedMember;
      final matchesSearch = searchQuery.isEmpty ||
          t.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.categoryName.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesMember && matchesSearch;
    }).toList();

    final budgets = [
      ('Supermercado y Alimentación', 600.0),
      ('Servicios Básicos (Luz/Agua/Net)', 180.0),
      ('Educación y Hogar', 350.0),
      ('Salud y Bienestar', 200.0),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Tarjeta Principal de Patrimonio y Salud Financiera
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patrimonio Disponible (${accounts.length} Cuentas)',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(currency.format(totalBalance),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      children: [
                        Text('▲ Ingresos Mes: ${currency.format(income)}',
                            style: TextStyle(
                                color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                        Text('▼ Gastos Mes: ${currency.format(expense)}',
                            style:
                                TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Text('Salud Financiera',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$healthScore / 100',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text('Tasa Ahorro: ${savingsRate.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Chips de filtro por miembro
        const Text('Gastos por Integrante del Hogar',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('Todos (${currency.format(expense)})'),
              selected: selectedMember == null,
              onSelected: (_) => ref.read(selectedMemberFilterProvider.notifier).state = null,
            ),
            ...members.map((m) {
              final mSpent = allTx
                  .where((t) => t.type == 2 && t.memberName == m)
                  .fold(0.0, (s, t) => s + t.amount);
              return ChoiceChip(
                label: Text('$m (${currency.format(mSpent)})'),
                selected: selectedMember == m,
                onSelected: (_) => ref.read(selectedMemberFilterProvider.notifier).state = m,
              );
            }),
          ],
        ),
        const SizedBox(height: 20),

        // Presupuestos mensuales
        const Text('Control de Presupuestos Mensuales',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...budgets.map((b) {
          final spent = allTx
              .where((t) => t.type == 2 && t.categoryName == b.$1)
              .fold(0.0, (s, t) => s + t.amount);
          final progress = (spent / b.$2).clamp(0.0, 1.0);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(b.$1, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text('${(progress * 100).toInt()}%',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: progress > 0.85 ? Colors.red : Colors.teal)),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(4),
                    color: progress > 0.85 ? Colors.red : null,
                  ),
                  const SizedBox(height: 4),
                  Text('${currency.format(spent)} de ${currency.format(b.$2)} disponibles'),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // Buscador y Movimientos Recientes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Movimientos Recientes',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('${filteredTx.length} registros', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'Buscar por descripción o categoría...',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        ...filteredTx.map((t) {
          final isInc = t.type == 1;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
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
  }
}

// ============================================================================
// PESTAÑA 2: ANALÍTICA GRÁFICA & EXPORTACIÓN CONTABLE A EXCEL / CSV
// ============================================================================
class AnalyticsAndExportView extends ConsumerWidget {
  const AnalyticsAndExportView({super.key});

  String _generateCsv(List<TxItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('Fecha,Tipo,Categoria,Descripcion,Cuenta,Miembro,Monto_USD');
    for (final t in items) {
      final tipo = t.type == 1 ? 'INGRESO' : 'GASTO';
      final fecha = DateFormat('yyyy-MM-dd').format(t.date);
      final cleanDesc = t.description.replaceAll(',', ' ');
      final cleanCat = t.categoryName.replaceAll(',', ' ');
      buffer.writeln(
          '$fecha,$tipo,$cleanCat,$cleanDesc,${t.accountName},${t.memberName},${t.amount.toStringAsFixed(2)}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTx = ref.watch(transactionsListProvider);
    final isPro = ref.watch(isProPlanProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final expenses = allTx.where((t) => t.type == 2).toList();
    final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);

    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory[e.categoryName] = (byCategory[e.categoryName] ?? 0) + e.amount;
    }

    final sortedCats = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analítica Financiera y Cierre Contable',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Distribución porcentual del gasto y exportación a Excel / CSV',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                if (!isPro) {
                  ref.read(navIndexProvider.notifier).state = 4;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('La exportación a Excel/CSV es exclusiva de Cash Pro.')),
                  );
                  return;
                }
                final csv = _generateCsv(allTx);
                Clipboard.setData(ClipboardData(text: csv));
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.table_view, color: Colors.teal),
                        SizedBox(width: 8),
                        Expanded(child: Text('Reporte CSV / Excel Generado')),
                      ],
                    ),
                    content: SizedBox(
                      width: 520,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              '✓ El contenido CSV ya fue copiado a tu portapapeles listo para pegar en Excel o Google Sheets:'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              csv,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 11, color: Colors.greenAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Listo'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Exportar Excel / CSV'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Distribución de Gastos por Categoría',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...sortedCats.map((entry) {
                  final pct = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                                '${currency.format(entry.value)} (${(pct * 100).toStringAsFixed(1)}%)'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: pct,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 3: METAS DE AHORRO FAMILIAR (SAVINGS GOALS)
// ============================================================================
class SavingsGoalsView extends ConsumerWidget {
  const SavingsGoalsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Metas de Ahorro Familiar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Objetivos financieros del hogar con seguimiento de progreso',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        ...goals.map((g) {
          final pct = (g.currentAmount / g.targetAmount).clamp(0.0, 1.0);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(g.title,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                      Chip(label: Text('Meta: ${g.deadline}')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Ahorrado: ${currency.format(g.currentAmount)} de ${currency.format(g.targetAmount)} (${(pct * 100).toInt()}%)'),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          final updated = goals.map((item) {
                            if (item.id == g.id) {
                              return item.copyWith(currentAmount: item.currentAmount + 100);
                            }
                            return item;
                          }).toList();
                          ref.read(savingsGoalsProvider.notifier).state = updated;
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Abonar +\$100'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 4: PAGOS FIJOS Y SUSCRIPCIONES RECURRENTES DEL HOGAR
// ============================================================================
class RecurringBillsView extends ConsumerWidget {
  const RecurringBillsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(recurringBillsProvider);
    final session = ref.watch(authSessionProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Pagos Fijos y Suscripciones del Hogar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Automatiza el registro de tus obligaciones mensuales en un clic',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        ...bills.map((b) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: b.isPaid ? Colors.green.shade100 : Colors.amber.shade100,
                  child: Icon(b.isPaid ? Icons.check : Icons.schedule,
                      color: b.isPaid ? Colors.green.shade800 : Colors.amber.shade900),
                ),
                title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${b.category} • Vence el día ${b.dueDay} de cada mes'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(currency.format(b.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 12),
                    if (b.isPaid)
                      const Chip(label: Text('Pagado'))
                    else
                      FilledButton(
                        onPressed: () {
                          // Marcar como pagado y agregar a transacciones
                          ref.read(recurringBillsProvider.notifier).state = bills
                              .map((item) =>
                                  item.id == b.id ? item.copyWith(isPaid: true) : item)
                              .toList();

                          final txList = ref.read(transactionsListProvider);
                          ref.read(transactionsListProvider.notifier).state = [
                            TxItem(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              description: 'Pago Mensual: ${b.title}',
                              amount: b.amount,
                              type: 2,
                              categoryName: b.category,
                              accountName: 'Cuenta Bancaria Principal',
                              memberName: session?.fullName ?? 'Hogar',
                            ),
                            ...txList,
                          ];
                        },
                        child: const Text('Pagar Ahora'),
                      ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 5: CUENTAS BANCARIAS & MOTOR DE MONETIZACIÓN (PAYWALL CASH PRO)
// ============================================================================
class AccountsAndProPlanView extends ConsumerWidget {
  const AccountsAndProPlanView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final isPro = ref.watch(isProPlanProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Cuentas y Billeteras del Hogar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...accounts.map((a) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.account_balance)),
                title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Tipo: ${a.type} • Moneda: USD'),
                trailing: Text(currency.format(a.balance),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )),
        const SizedBox(height: 28),

        // MOTOR DE MONETIZACIÓN SAAS (CASH PRO PAYWALL)
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Colors.amber.shade700, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.amber.shade700, size: 32),
                        const SizedBox(width: 10),
                        const Text('Cash Pro Familiar (SaaS)',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Switch(
                      value: isPro,
                      onChanged: (v) => ref.read(isProPlanProvider.notifier).state = v,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isPro
                      ? 'Estado actual: Suscripción PRO Activa (\$4.99/mes o \$39.99/año). Todas las funciones comerciales están desbloqueadas.'
                      : 'Estado actual: Plan Básico Gratuito. Activa el interruptor para simular la compra de Cash Pro.',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Divider(height: 28),
                const Text('Beneficios incluidos en tu modelo de monetización:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const ListTile(
                  dense: true,
                  leading: Icon(Icons.check_circle, color: Colors.teal),
                  title: Text('Miembros del hogar y cuentas bancarias ilimitadas'),
                ),
                const ListTile(
                  dense: true,
                  leading: Icon(Icons.check_circle, color: Colors.teal),
                  title: Text('Exportación contable a Excel / CSV con un clic'),
                ),
                const ListTile(
                  dense: true,
                  leading: Icon(Icons.check_circle, color: Colors.teal),
                  title: Text('Metas de ahorro familiar y alertas de pagos recurrentes'),
                ),
                const ListTile(
                  dense: true,
                  leading: Icon(Icons.check_circle, color: Colors.teal),
                  title: Text('Score de Salud Financiera y Analítica avanzada'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// MODAL DE REGISTRO DE MOVIMIENTOS (GASTO / INGRESO / ACTUALIZACIÓN DE SALDO)
// ============================================================================
class NewTxModal extends ConsumerStatefulWidget {
  const NewTxModal({super.key});
  @override
  ConsumerState<NewTxModal> createState() => _NewTxModalState();
}

class _NewTxModalState extends ConsumerState<NewTxModal> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _type = 2; // 2 = Gasto, 1 = Ingreso
  String _category = 'Supermercado y Alimentación';
  String _accountName = 'Cuenta Bancaria Principal';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final accounts = ref.watch(accountsProvider);
    final categories = _type == 2
        ? [
            'Supermercado y Alimentación',
            'Servicios Básicos (Luz/Agua/Net)',
            'Educación y Hogar',
            'Salud y Bienestar'
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
            value: _accountName,
            decoration:
                const InputDecoration(labelText: 'Cuenta', border: OutlineInputBorder()),
            items: accounts
                .map((a) => DropdownMenuItem(value: a.name, child: Text(a.name)))
                .toList(),
            onChanged: (v) => setState(() => _accountName = v!),
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

              // 1. Insertar movimiento
              final list = ref.read(transactionsListProvider);
              ref.read(transactionsListProvider.notifier).state = [
                TxItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  description: _descCtrl.text.isEmpty ? 'Movimiento' : _descCtrl.text,
                  amount: amt,
                  type: _type,
                  categoryName: _category,
                  accountName: _accountName,
                  memberName: session?.fullName ?? 'Hogar',
                ),
                ...list,
              ];

              // 2. Actualizar el saldo de la cuenta seleccionada
              ref.read(accountsProvider.notifier).state = accounts.map((acc) {
                if (acc.name == _accountName) {
                  final delta = _type == 1 ? amt : -amt;
                  return acc.copyWith(balance: acc.balance + delta);
                }
                return acc;
              }).toList();

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
