import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ProviderScope(child: CashApp()));
}

// ============================================================================
// CONFIGURACIÓN DE CREDENCIALES DE PASARELAS (PAYPHONE WEB & REVENUECAT MOBILE)
// ============================================================================
class BillingConfig {
  // Payphone Business (Ecuador / LatAm - Web)
  static const String payphoneStoreId = 'STORE_ID_PAYPHONE_BUSINESS';
  static const String payphoneConfirmEndpoint = '/api/billing/payphone/confirm';

  // RevenueCat (Google Play Billing & Apple StoreKit 2)
  static const String revenueCatGooglePlayApiKey = 'goog_PUBLIC_SDK_KEY_ANDROID';
  static const String revenueCatAppStoreApiKey = 'appl_PUBLIC_SDK_KEY_IOS';
  static const String entitlementId = 'cash_pro';
  static const String monthlyOfferingId = 'cash_pro_monthly_499';
  static const String annualOfferingId = 'cash_pro_annual_3999';
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
  final String type;
  final double balance;
  AccountModel({required this.id, required this.name, required this.type, required this.balance});

  AccountModel copyWith({double? balance}) =>
      AccountModel(id: id, name: name, type: type, balance: balance ?? this.balance);
}

class TxItem {
  final String id;
  final String description;
  final double amount;
  final int type; // 1 = Ingreso, 2 = Gasto
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

class ActiveSubscriptionInfo {
  final bool isPro;
  final String planName;
  final String gateway; // Payphone Web | RevenueCat Google Play | RevenueCat App Store
  final String lastAuthCode;
  final String selectedBillingCycle; // monthly | annual

  ActiveSubscriptionInfo({
    required this.isPro,
    required this.planName,
    required this.gateway,
    required this.lastAuthCode,
    this.selectedBillingCycle = 'annual',
  });

  ActiveSubscriptionInfo copyWith({
    bool? isPro,
    String? planName,
    String? gateway,
    String? lastAuthCode,
    String? selectedBillingCycle,
  }) =>
      ActiveSubscriptionInfo(
        isPro: isPro ?? this.isPro,
        planName: planName ?? this.planName,
        gateway: gateway ?? this.gateway,
        lastAuthCode: lastAuthCode ?? this.lastAuthCode,
        selectedBillingCycle: selectedBillingCycle ?? this.selectedBillingCycle,
      );
}

// Providers globales
final authSessionProvider = StateProvider<AuthSession?>((ref) => null);
final isDarkModeProvider = StateProvider<bool>((ref) => false);
final navIndexProvider = StateProvider<int>((ref) => 0);
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final gatewayPreviewModeProvider = StateProvider<String>((ref) => kIsWeb ? 'WEB_PAYPHONE' : 'MOBILE_REVENUECAT');

final subscriptionProvider = StateProvider<ActiveSubscriptionInfo>((ref) => ActiveSubscriptionInfo(
      isPro: false,
      planName: 'Plan Hogar Básico (Gratis)',
      gateway: 'Ninguna',
      lastAuthCode: '-',
      selectedBillingCycle: 'annual',
    ));

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
    ]);

// ============================================================================
// APP PRINCIPAL
// ============================================================================
class CashApp extends ConsumerWidget {
  const CashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return MaterialApp(
      title: 'Cash Pro · Payphone & RevenueCat',
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
// LOGIN MULTI-USUARIO (JWT)
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
                const Text('Cash · Hogar',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const Text('Monetización integrada: Payphone Web & RevenueCat Mobile',
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
                        const Text('Iniciar Sesión (JWT)',
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
                const SizedBox(height: 20),
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
// SHELL ADAPTATIVO
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
    final sub = ref.watch(subscriptionProvider);

    final pages = [
      const DashboardView(),
      const AnalyticsAndExportView(),
      const SavingsGoalsView(),
      const RecurringBillsView(),
      const MonetizationGatewaysView(),
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
                InkWell(
                  onTap: () => ref.read(navIndexProvider.notifier).state = 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sub.isPro ? Colors.amber.shade700 : Colors.teal.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sub.isPro ? '★ PRO ACTIVO (${sub.gateway})' : 'MEJORAR A PRO',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (isWide) ...[
                  const SizedBox(width: 16),
                  Text('•  ${session?.fullName} (${session?.role})',
                      style: const TextStyle(fontSize: 13)),
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
                      label: Text('Pagos Fijos'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.credit_card_outlined),
                      selectedIcon: Icon(Icons.credit_card),
                      label: Text('Payphone & RevenueCat'),
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
                    NavigationDestination(icon: Icon(Icons.credit_card), label: 'Pasarelas'),
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
// PESTAÑA 1: DASHBOARD PRINCIPAL
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
                        Text('▲ Ingresos: ${currency.format(income)}',
                            style: TextStyle(
                                color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                        Text('▼ Gastos: ${currency.format(expense)}',
                            style:
                                TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Text('Salud Financiera',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('$healthScore / 100',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text('Ahorro: ${savingsRate.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Gastos por Integrante del Hogar',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
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
        TextField(
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'Buscar movimiento o categoría...',
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
// PESTAÑA 2: ANALÍTICA & EXPORTACIÓN CONTABLE CSV (REQUIERE PRO)
// ============================================================================
class AnalyticsAndExportView extends ConsumerWidget {
  const AnalyticsAndExportView({super.key});

  String _generateCsv(List<TxItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('Fecha,Tipo,Categoria,Descripcion,Cuenta,Miembro,Monto_USD');
    for (final t in items) {
      final tipo = t.type == 1 ? 'INGRESO' : 'GASTO';
      final fecha = DateFormat('yyyy-MM-dd').format(t.date);
      buffer.writeln(
          '$fecha,$tipo,${t.categoryName},${t.description},${t.accountName},${t.memberName},${t.amount.toStringAsFixed(2)}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTx = ref.watch(transactionsListProvider);
    final sub = ref.watch(subscriptionProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final expenses = allTx.where((t) => t.type == 2).toList();
    final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);
    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory[e.categoryName] = (byCategory[e.categoryName] ?? 0) + e.amount;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text('Analítica y Exportación Excel / CSV',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            FilledButton.icon(
              onPressed: () {
                if (!sub.isPro) {
                  ref.read(navIndexProvider.notifier).state = 4;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Activa Cash Pro con Payphone o Google Play / App Store para exportar a Excel.')),
                  );
                  return;
                }
                final csv = _generateCsv(allTx);
                Clipboard.setData(ClipboardData(text: csv));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✓ CSV copiado al portapapeles listo para pegar en Excel.')),
                );
              },
              icon: Icon(sub.isPro ? Icons.download : Icons.lock),
              label: Text(sub.isPro ? 'Exportar CSV' : 'Exportar CSV (Pro)'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...byCategory.entries.map((e) {
          final pct = totalExpense > 0 ? (e.value / totalExpense) : 0.0;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: LinearProgressIndicator(value: pct, minHeight: 8),
              trailing: Text('${currency.format(e.value)} (${(pct * 100).toInt()}%)'),
            ),
          );
        }),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 3: METAS DE AHORRO
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
        const SizedBox(height: 16),
        ...goals.map((g) {
          final pct = (g.currentAmount / g.targetAmount).clamp(0.0, 1.0);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: pct, minHeight: 10),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${currency.format(g.currentAmount)} de ${currency.format(g.targetAmount)}'),
                      FilledButton.tonal(
                        onPressed: () {
                          ref.read(savingsGoalsProvider.notifier).state = goals
                              .map((item) => item.id == g.id
                                  ? item.copyWith(currentAmount: item.currentAmount + 100)
                                  : item)
                              .toList();
                        },
                        child: const Text('Abonar +\$100'),
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
// PESTAÑA 4: PAGOS FIJOS Y SUSCRIPCIONES
// ============================================================================
class RecurringBillsView extends ConsumerWidget {
  const RecurringBillsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(recurringBillsProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Pagos Fijos Mensuales',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...bills.map((b) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(b.isPaid ? Icons.check_circle : Icons.schedule,
                    color: b.isPaid ? Colors.green : Colors.amber.shade800),
                title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Vence el día ${b.dueDay} • ${currency.format(b.amount)}'),
                trailing: b.isPaid
                    ? const Chip(label: Text('Pagado'))
                    : FilledButton(
                        onPressed: () {
                          ref.read(recurringBillsProvider.notifier).state = bills
                              .map((item) =>
                                  item.id == b.id ? item.copyWith(isPaid: true) : item)
                              .toList();
                        },
                        child: const Text('Registrar Pago'),
                      ),
              ),
            )),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 5: CENTRO DE MONETIZACIÓN (PAYPHONE WEB + REVENUECAT GOOGLE PLAY / APP STORE)
// ============================================================================
class MonetizationGatewaysView extends ConsumerWidget {
  const MonetizationGatewaysView({super.key});

  void _openPayphoneCheckoutModal(BuildContext context, WidgetRef ref, bool isAnnual) {
    final amountUsd = isAnnual ? 39.99 : 4.99;
    final totalCents = isAnnual ? 3999 : 499;
    final baseCents = (totalCents / 1.15).round();
    final taxCents = totalCents - baseCents;
    final clientTxId = 'CASH-${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.payment, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payphone Cajita de Pagos',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            Text('Visa • Mastercard • Diners • Saldo Payphone',
                                style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isAnnual
                              ? 'Plan Anual Cash Pro Familiar'
                              : 'Plan Mensual Cash Pro Familiar',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('clientTransactionId: $clientTxId',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                      Text(
                          'Payload Payphone (Centavos): amount=$totalCents | base=$baseCents | tax(15%)=$taxCents',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Número de Tarjeta o Teléfono Payphone',
                    hintText: '4532 •••• •••• 8891  o  0991234567',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Exp (MM/AA)',
                          hintText: '08/29',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'CVC',
                          hintText: '•••',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange.shade600),
                  onPressed: () {
                    final authCode = 'PP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    ref.read(subscriptionProvider.notifier).state = ActiveSubscriptionInfo(
                      isPro: true,
                      planName: isAnnual ? 'Cash Pro Anual (\$39.99)' : 'Cash Pro Mensual (\$4.99)',
                      gateway: 'Payphone Web (Confirm V2)',
                      lastAuthCode: authCode,
                      selectedBillingCycle: isAnnual ? 'annual' : 'monthly',
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '✓ Pago confirmado en /api/button/V2/Confirm (Código $authCode). ¡Cash Pro Activado!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Pagar \$${amountUsd.toStringAsFixed(2)} USD y Confirmar V2'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRevenueCatStoreSheet(BuildContext context, WidgetRef ref, bool isAnnual) {
    final amountUsd = isAnnual ? 39.99 : 4.99;
    final sku = isAnnual ? BillingConfig.annualOfferingId : BillingConfig.monthlyOfferingId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.shop_two, color: Colors.teal, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Google Play Billing / Apple StoreKit 2',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Gestionado vía RevenueCat SDK • Entitlement: ${BillingConfig.entitlementId}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isAnnual ? 'Suscripción Anual Cash Pro' : 'Suscripción Mensual Cash Pro',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Product ID: $sku\nRenovación automática cancelable en cualquier momento.'),
              trailing: Text('\$${amountUsd.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                final rcTx = 'RC-GPA.${DateTime.now().millisecondsSinceEpoch}';
                ref.read(subscriptionProvider.notifier).state = ActiveSubscriptionInfo(
                  isPro: true,
                  planName: isAnnual ? 'Cash Pro Anual (\$39.99)' : 'Cash Pro Mensual (\$4.99)',
                  gateway: 'RevenueCat (Google Play / App Store)',
                  lastAuthCode: rcTx,
                  selectedBillingCycle: isAnnual ? 'annual' : 'monthly',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '✓ Entitlement "${BillingConfig.entitlementId}" activo vía RevenueCat ($rcTx).')),
                );
              },
              icon: const Icon(Icons.fingerprint),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Suscribirse con 1-Toque (Play Store / App Store)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final previewMode = ref.watch(gatewayPreviewModeProvider);
    final isAnnual = sub.selectedBillingCycle == 'annual';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Pasarelas de Pago y Suscripciones',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const Text(
            'Payphone (Cajita de Pagos V2) para Web  •  RevenueCat para Google Play y Apple App Store',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),

        // Selector de canal para previsualizar ambos flujos desde cualquier dispositivo
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'WEB_PAYPHONE',
              icon: Icon(Icons.language),
              label: Text('Canal Web: Payphone Ecuador'),
            ),
            ButtonSegment(
              value: 'MOBILE_REVENUECAT',
              icon: Icon(Icons.phone_iphone),
              label: Text('Canal Móvil: RevenueCat (Play/App Store)'),
            ),
          ],
          selected: {previewMode},
          onSelectionChanged: (s) => ref.read(gatewayPreviewModeProvider.notifier).state = s.first,
        ),
        const SizedBox(height: 20),

        // Estado actual de la suscripción
        Card(
          elevation: 0,
          color: sub.isPro
              ? Colors.teal.withOpacity(0.12)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: sub.isPro ? Colors.teal : Colors.grey.shade400),
          ),
          child: ListTile(
            leading: Icon(
              sub.isPro ? Icons.verified : Icons.info_outline,
              color: sub.isPro ? Colors.teal : Colors.grey,
              size: 34,
            ),
            title: Text(sub.planName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Pasarela: ${sub.gateway}  •  Ref/Auth: ${sub.lastAuthCode}'),
            trailing: sub.isPro
                ? OutlinedButton(
                    onPressed: () {
                      ref.read(subscriptionProvider.notifier).state = sub.copyWith(
                        isPro: false,
                        planName: 'Plan Hogar Básico (Gratis)',
                        gateway: 'Ninguna',
                        lastAuthCode: '-',
                      );
                    },
                    child: const Text('Cancelar Prueba'),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 20),

        // Selector de Ciclo de Facturación (Mensual vs Anual con 33% de descuento)
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => ref.read(subscriptionProvider.notifier).state =
                    sub.copyWith(selectedBillingCycle: 'monthly'),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: !isAnnual ? Colors.teal : Colors.grey.shade300,
                      width: !isAnnual ? 2.5 : 1,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan Mensual', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text('\$4.99 / mes',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Facturado mensualmente (499 centavos)',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => ref.read(subscriptionProvider.notifier).state =
                    sub.copyWith(selectedBillingCycle: 'annual'),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isAnnual ? Colors.teal : Colors.grey.shade300,
                      width: isAnnual ? 2.5 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Plan Anual',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('AHORRA 33%',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('\$39.99 / año',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Equivale a \$3.33/mes (3999 centavos)',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Tarjeta específica según el canal activo (Payphone Web vs RevenueCat Mobile)
        if (previewMode == 'WEB_PAYPHONE')
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.deepOrange.shade600, size: 30),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Checkout Web con Payphone Business',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                            Text(
                                'Acepta Visa, Mastercard, Diners, Discover y Saldo Payphone • Confirmación automática V2',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                      '• Paso 1: Llama a POST /api/billing/payphone/prepare para generar el clientTransactionId.\n'
                      '• Paso 2: Abre la Cajita de Pagos y procesa el cobro 3DS.\n'
                      '• Paso 3: Confirma en POST https://pay.payphonetodoesposible.com/api/button/V2/Confirm antes de 5 minutos.',
                      style: TextStyle(fontSize: 13, height: 1.5)),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange.shade600),
                    onPressed: () => _openPayphoneCheckoutModal(context, ref, isAnnual),
                    icon: const Icon(Icons.launch),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                          'Pagar con Payphone (${isAnnual ? "\$39.99 USD / Año" : "\$4.99 USD / Mes"})'),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phone_android, color: Colors.teal, size: 30),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Suscripción Móvil con RevenueCat (In-App Purchases)',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                            Text(
                                'Google Play Billing (Android) & Apple StoreKit 2 (iOS) sincronizados por Webhook',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                      '• Configura PurchasesConfiguration con tus llaves goog_ y appl_.\n'
                      '• Desbloquea el Entitlement "cash_pro" y envía un Webhook a POST /api/billing/revenuecat/webhook.\n'
                      '• Incluye el botón obligatorio de "Restaurar Compras" exigido por Apple y Google.',
                      style: TextStyle(fontSize: 13, height: 1.5)),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _openRevenueCatStoreSheet(context, ref, isAnnual),
                    icon: const Icon(Icons.workspace_premium),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                          'Suscribirse vía Google Play / App Store (${isAnnual ? "\$39.99" : "\$4.99"})'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(subscriptionProvider.notifier).state = ActiveSubscriptionInfo(
                        isPro: true,
                        planName: 'Cash Pro Restaurado',
                        gateway: 'RevenueCat RestorePurchases()',
                        lastAuthCode: 'RC-RESTORED-OK',
                        selectedBillingCycle: isAnnual ? 'annual' : 'monthly',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                '✓ Compras restauradas exitosamente desde Google Play / App Store.')),
                      );
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Restaurar Compras Anteriores (Restore Purchases)'),
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
// MODAL DE REGISTRO DE MOVIMIENTOS
// ============================================================================
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final amt = double.tryParse(_amountCtrl.text) ?? 0;
              if (amt <= 0) return;

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

              ref.read(accountsProvider.notifier).state = accounts.map((acc) {
                if (acc.name == _accountName) {
                  final delta = _type == 1 ? amt : -amt;
                  return acc.copyWith(balance: acc.balance + delta);
                }
                return acc;
              }).toList();

              Navigator.pop(context);
            },
            child: const Text('Guardar Movimiento'),
          ),
        ],
      ),
    );
  }
}
