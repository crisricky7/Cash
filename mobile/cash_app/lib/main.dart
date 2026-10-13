import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ProviderScope(child: CashApp()));
}

class BillingConfig {
  static const String entitlementId = 'cash_pro';
  static const String monthlyOfferingId = 'cash_pro_monthly_499';
  static const String annualOfferingId = 'cash_pro_annual_3999';
}

// ============================================================================
// MODELOS DE DOMINIO Y PROVIDERS DINÁMICOS
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
  final String type; // Banco, Billetera Digital, Efectivo, Tarjeta de Crédito, Ahorro, Cooperativa
  final double balance;
  AccountModel({required this.id, required this.name, required this.type, required this.balance});

  AccountModel copyWith({String? name, String? type, double? balance}) => AccountModel(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
      );
}

class CategoryModel {
  final String id;
  final String name;
  final int type; // 1 = Ingreso, 2 = Gasto
  final double monthlyBudget;
  final String bucket503020; // Necesidades (50%) | Deseos/Estilo de Vida (30%) | Ahorro/Deuda (20%)
  final String taxGroup; // Rubro deducible impuestos
  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.monthlyBudget,
    this.bucket503020 = 'Necesidades (50%)',
    this.taxGroup = 'General',
  });
}

class TxItem {
  final String id;
  final String description;
  final double amount;
  final int type; // 1 = Ingreso, 2 = Gasto, 3 = Transferencia / Recarga Billetera
  final String categoryName;
  final String accountName;
  final String memberName;
  final DateTime date;
  final bool isSharedHouseholdExpense;
  TxItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryName,
    required this.accountName,
    required this.memberName,
    DateTime? date,
    this.isSharedHouseholdExpense = true,
  }) : date = date ?? DateTime.now();
}

class CreditInstallmentModel {
  final String id;
  final String cardName;
  final String description;
  final double totalAmount;
  final int totalMonths;
  final int paidMonths;
  final int cutOffDay;
  final int paymentDueDay;

  CreditInstallmentModel({
    required this.id,
    required this.cardName,
    required this.description,
    required this.totalAmount,
    required this.totalMonths,
    required this.paidMonths,
    this.cutOffDay = 14,
    this.paymentDueDay = 2,
  });

  double get monthlyQuota => totalMonths > 0 ? totalAmount / totalMonths : 0.0;
  double get remainingBalance => (totalMonths - paidMonths) * monthlyQuota;

  CreditInstallmentModel copyWith({int? paidMonths}) => CreditInstallmentModel(
        id: id,
        cardName: cardName,
        description: description,
        totalAmount: totalAmount,
        totalMonths: totalMonths,
        paidMonths: paidMonths ?? this.paidMonths,
        cutOffDay: cutOffDay,
        paymentDueDay: paymentDueDay,
      );
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
  final String gateway;
  final String lastAuthCode;
  final String selectedBillingCycle;

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

// Estado global
final authSessionProvider = StateProvider<AuthSession?>((ref) => null);
final isDarkModeProvider = StateProvider<bool>((ref) => false);
final navIndexProvider = StateProvider<int>((ref) => 0);
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final gatewayPreviewModeProvider =
    StateProvider<String>((ref) => kIsWeb ? 'WEB_PAYPHONE' : 'MOBILE_REVENUECAT');

final subscriptionProvider = StateProvider<ActiveSubscriptionInfo>((ref) => ActiveSubscriptionInfo(
      isPro: true,
      planName: 'Cash Pro Familiar (Demo Activo)',
      gateway: 'Sandbox',
      lastAuthCode: 'PRO-DEMO',
      selectedBillingCycle: 'annual',
    ));

final accountsProvider = StateProvider<List<AccountModel>>((ref) => [
      AccountModel(id: 'a1', name: 'Cuenta Bancaria Principal', type: 'Banco', balance: 1850.00),
      AccountModel(
          id: 'a2',
          name: 'Billetera Digital (Payphone / Deuna)',
          type: 'Billetera Digital',
          balance: 195.00),
      AccountModel(
          id: 'a3', name: 'Efectivo Hogar (Caja Chica)', type: 'Efectivo', balance: 280.00),
      AccountModel(id: 'a4', name: 'Fondo de Reserva Familiar', type: 'Ahorro', balance: 3200.00),
    ]);

final categoriesProvider = StateProvider<List<CategoryModel>>((ref) => [
      CategoryModel(
        id: 'c1',
        name: 'Supermercado y Alimentación',
        type: 2,
        monthlyBudget: 600.00,
        bucket503020: 'Necesidades (50%)',
        taxGroup: 'Alimentación',
      ),
      CategoryModel(
        id: 'c2',
        name: 'Servicios Básicos (Luz/Agua/Net)',
        type: 2,
        monthlyBudget: 180.00,
        bucket503020: 'Necesidades (50%)',
        taxGroup: 'Vivienda',
      ),
      CategoryModel(
        id: 'c3',
        name: 'Educación y Hogar',
        type: 2,
        monthlyBudget: 350.00,
        bucket503020: 'Necesidades (50%)',
        taxGroup: 'Educación',
      ),
      CategoryModel(
        id: 'c4',
        name: 'Salud y Bienestar',
        type: 2,
        monthlyBudget: 200.00,
        bucket503020: 'Necesidades (50%)',
        taxGroup: 'Salud',
      ),
      CategoryModel(
        id: 'c5',
        name: 'Restaurantes, Salidas y Ocio',
        type: 2,
        monthlyBudget: 180.00,
        bucket503020: 'Deseos / Estilo de Vida (30%)',
        taxGroup: 'Turismo / Consumo',
      ),
      CategoryModel(
        id: 'c6',
        name: 'Ingresos / Salario Mensual',
        type: 1,
        monthlyBudget: 0.00,
      ),
      CategoryModel(
        id: 'c7',
        name: 'Honorarios / Ingresos Extra',
        type: 1,
        monthlyBudget: 0.00,
      ),
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
        description: 'Pago Rápido QR en Panadería y Café (Gasto Hormiga)',
        amount: 9.50,
        type: 2,
        categoryName: 'Restaurantes, Salidas y Ocio',
        accountName: 'Billetera Digital (Payphone / Deuna)',
        memberName: 'Pareja',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TxItem(
        id: 't3',
        description: 'Pago Fibra Óptica + Energía Eléctrica',
        amount: 92.50,
        type: 2,
        categoryName: 'Servicios Básicos (Luz/Agua/Net)',
        accountName: 'Cuenta Bancaria Principal',
        memberName: 'Pareja',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TxItem(
        id: 't4',
        description: 'Recarga de Saldo a Billetera Digital',
        amount: 100.00,
        type: 3,
        categoryName: 'Transferencia / Recarga',
        accountName: 'Cuenta Bancaria Principal → Billetera Digital (Payphone / Deuna)',
        memberName: 'Admin Hogar',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TxItem(
        id: 't5',
        description: 'Ingreso Salario Mensual Hogar',
        amount: 2800.00,
        type: 1,
        categoryName: 'Ingresos / Salario Mensual',
        accountName: 'Cuenta Bancaria Principal',
        memberName: 'Admin Hogar',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      TxItem(
        id: 't6',
        description: 'Útiles, Libros y Colación Escolar',
        amount: 48.00,
        type: 2,
        categoryName: 'Educación y Hogar',
        accountName: 'Efectivo Hogar (Caja Chica)',
        memberName: 'Familiar',
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ]);

final installmentsProvider = StateProvider<List<CreditInstallmentModel>>((ref) => [
      CreditInstallmentModel(
        id: 'i1',
        cardName: 'Visa Titanium Hogar',
        description: 'Refrigeradora Inverter Familiar (Diferido Sin Intereses)',
        totalAmount: 1200.00,
        totalMonths: 12,
        paidMonths: 5,
        cutOffDay: 14,
        paymentDueDay: 2,
      ),
      CreditInstallmentModel(
        id: 'i2',
        cardName: 'Mastercard Black',
        description: 'Matrícula y Equipamiento Escolar Anual',
        totalAmount: 600.00,
        totalMonths: 6,
        paidMonths: 3,
        cutOffDay: 20,
        paymentDueDay: 8,
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
    ]);

IconData getAccountTypeIcon(String type) {
  switch (type) {
    case 'Billetera Digital':
      return Icons.qr_code_2;
    case 'Efectivo':
      return Icons.payments_outlined;
    case 'Tarjeta de Crédito':
      return Icons.credit_card;
    case 'Ahorro':
      return Icons.savings_outlined;
    default:
      return Icons.account_balance;
  }
}

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
      title: 'Cash Pro · Finanzas Inteligentes del Hogar',
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
                const Text('Cash · Hogar Pro',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const Text(
                    'Escáner Facturas • Tarjetas & Diferidos • Billeteras Digitales • Copiloto 50/30/20',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
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
// SHELL ADAPTATIVO CON ACCESO A ESCÁNER DE FACTURAS Y 5 MÓDULOS COMERCIALES
// ============================================================================
class ResponsiveHomeShell extends ConsumerWidget {
  const ResponsiveHomeShell({super.key});

  void _openNewTransaction(BuildContext context, bool isWide, {int initialType = 2}) {
    if (isWide) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: NewTxModal(initialType: initialType),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => NewTxModal(initialType: initialType),
      );
    }
  }

  void _openInvoiceScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: const SmartInvoiceScannerModal(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final navIdx = ref.watch(navIndexProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final sub = ref.watch(subscriptionProvider);

    final pages = [
      const DashboardView(),
      const CatalogsSettingsView(),
      const Copiloto503020AndExportView(),
      const CreditCardsGoalsAndRecurringView(),
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
                      sub.isPro ? '★ PRO ACTIVO' : 'MEJORAR A PRO',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (isWide) ...[
                  const SizedBox(width: 14),
                  Text('•  ${session?.fullName}', style: const TextStyle(fontSize: 13)),
                ]
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Escáner Inteligente de Factura (XML / OCR)',
                icon: const Icon(Icons.document_scanner_outlined),
                onPressed: () => _openInvoiceScanner(context),
              ),
              IconButton(
                tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => ref.read(isDarkModeProvider.notifier).state = !isDark,
              ),
              if (isWide) ...[
                OutlinedButton.icon(
                  onPressed: () => _openInvoiceScanner(context),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Escanear Factura XML/OCR'),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton.icon(
                    onPressed: () => _openNewTransaction(context, true, initialType: 2),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar'),
                  ),
                ),
              ],
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
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet),
                      label: Text('Cuentas & Billeteras'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights),
                      label: Text('Copiloto 50/30/20 & Split'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.credit_score_outlined),
                      selectedIcon: Icon(Icons.credit_score),
                      label: Text('Tarjetas, Diferidos & Metas'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.workspace_premium_outlined),
                      selectedIcon: Icon(Icons.workspace_premium),
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
                    NavigationDestination(
                        icon: Icon(Icons.account_balance_wallet), label: 'Billeteras'),
                    NavigationDestination(icon: Icon(Icons.insights), label: '50/30/20'),
                    NavigationDestination(icon: Icon(Icons.credit_score), label: 'Diferidos'),
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
// MODAL DIFERENCIADOR 1: ESCÁNER INTELIGENTE DE FACTURAS (OCR / XML SRI + IVA 15%)
// ============================================================================
class SmartInvoiceScannerModal extends ConsumerStatefulWidget {
  const SmartInvoiceScannerModal({super.key});
  @override
  ConsumerState<SmartInvoiceScannerModal> createState() => _SmartInvoiceScannerModalState();
}

class _SmartInvoiceScannerModalState extends ConsumerState<SmartInvoiceScannerModal> {
  final _merchantCtrl = TextEditingController(text: 'Corporación Favorita - Supermaxi');
  final _totalCtrl = TextEditingController(text: '115.00');
  String _selectedAccount = 'Billetera Digital (Payphone / Deuna)';

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final session = ref.watch(authSessionProvider);
    final total = double.tryParse(_totalCtrl.text) ?? 0.0;
    final subTotal = total / 1.15;
    final iva15 = total - subTotal;

    final lower = _merchantCtrl.text.toLowerCase();
    final detectedCategory = lower.contains('super') || lower.contains('maxi')
        ? 'Supermercado y Alimentación'
        : lower.contains('farmacia') || lower.contains('salud')
            ? 'Salud y Bienestar'
            : lower.contains('colegio') || lower.contains('educa')
                ? 'Educación y Hogar'
                : 'Restaurantes, Salidas y Ocio';

    final deductibleTag = detectedCategory == 'Supermercado y Alimentación'
        ? 'Rubro Deducible SRI: Alimentación'
        : detectedCategory == 'Salud y Bienestar'
            ? 'Rubro Deducible SRI: Salud'
            : 'Rubro Deducible SRI: Educación / Vivienda';

    if (!accounts.any((a) => a.name == _selectedAccount)) {
      _selectedAccount = accounts.first.name;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.document_scanner, color: Colors.teal),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Importador Inteligente de Factura (XML / OCR)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Desglosa IVA 15% y clasifica para Proyección de Gastos Personales',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.shopping_cart, size: 16),
                label: const Text('Demo: Factura Supermaxi (\$115)'),
                onPressed: () => setState(() {
                  _merchantCtrl.text = 'Corporación Favorita - Supermaxi';
                  _totalCtrl.text = '115.00';
                }),
              ),
              ActionChip(
                avatar: const Icon(Icons.local_pharmacy, size: 16),
                label: const Text('Demo: Farmacia Fybeca (\$46)'),
                onPressed: () => setState(() {
                  _merchantCtrl.text = 'Farmacias Fybeca S.A. - Medicinas';
                  _totalCtrl.text = '46.00';
                }),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _merchantCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Razón Social / Comercio Detectado',
              prefixIcon: Icon(Icons.storefront),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _totalCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor Total Factura (USD)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedAccount,
            decoration: const InputDecoration(
              labelText: 'Pagado con (Cuenta o Billetera Digital)',
              border: OutlineInputBorder(),
            ),
            items: accounts
                .map((a) => DropdownMenuItem(value: a.name, child: Text('${a.name} (${a.type})')))
                .toList(),
            onChanged: (v) => setState(() => _selectedAccount = v!),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Desglose Tributario Automático: Subtotal \$${subTotal.toStringAsFixed(2)}  +  IVA (15%) \$${iva15.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Categoría IA Asignada: $detectedCategory'),
                Text('✓ $deductibleTag',
                    style: const TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              if (total <= 0) return;
              final list = ref.read(transactionsListProvider);
              ref.read(transactionsListProvider.notifier).state = [
                TxItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  description:
                      'Factura: ${_merchantCtrl.text} (IVA 15%: \$${iva15.toStringAsFixed(2)})',
                  amount: total,
                  type: 2,
                  categoryName: detectedCategory,
                  accountName: _selectedAccount,
                  memberName: session?.fullName ?? 'Hogar',
                ),
                ...list,
              ];

              ref.read(accountsProvider.notifier).state = accounts.map((acc) {
                if (acc.name == _selectedAccount) {
                  return acc.copyWith(balance: acc.balance - total);
                }
                return acc;
              }).toList();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        '✓ Factura procesada, categorizada y descontada del saldo automáticamente.')),
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Importar Factura y Registrar Gasto'),
            ),
          ),
        ],
      ),
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
    final categories = ref.watch(categoriesProvider);
    final allTx = ref.watch(transactionsListProvider);
    final selectedMember = ref.watch(selectedMemberFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final totalBalance = accounts.fold(0.0, (s, a) => s + a.balance);
    final bankBalance = accounts
        .where((a) => a.type == 'Banco' || a.type == 'Ahorro' || a.type == 'Cooperativa')
        .fold(0.0, (s, a) => s + a.balance);
    final digitalWalletBalance = accounts
        .where((a) => a.type == 'Billetera Digital')
        .fold(0.0, (s, a) => s + a.balance);
    final cashBalance =
        accounts.where((a) => a.type == 'Efectivo').fold(0.0, (s, a) => s + a.balance);

    final income = allTx.where((t) => t.type == 1).fold(0.0, (s, t) => s + t.amount);
    final expense = allTx.where((t) => t.type == 2).fold(0.0, (s, t) => s + t.amount);
    final savingsRate = income > 0 ? ((income - expense) / income * 100).clamp(0.0, 100.0) : 0.0;
    final healthScore = (savingsRate * 1.4).clamp(45.0, 98.0).toInt();

    final members = allTx.where((t) => t.type == 2).map((t) => t.memberName).toSet().toList();
    final filteredTx = allTx.where((t) {
      final matchesMember = selectedMember == null || t.memberName == selectedMember;
      final matchesSearch = searchQuery.isEmpty ||
          t.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.categoryName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.accountName.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesMember && matchesSearch;
    }).toList();

    final expenseCategories = categories.where((c) => c.type == 2).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Patrimonio Total (${accounts.length} Opciones de Saldo)',
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(currency.format(totalBalance),
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          children: [
                            Text('▲ Ingresos Mes: ${currency.format(income)}',
                                style: TextStyle(
                                    color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                            Text('▼ Gastos Mes: ${currency.format(expense)}',
                                style: TextStyle(
                                    color: Colors.red.shade800, fontWeight: FontWeight.bold)),
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
                const Divider(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _BalancePill(
                      icon: Icons.account_balance,
                      label: 'Bancos y Ahorros',
                      amount: currency.format(bankBalance),
                    ),
                    _BalancePill(
                      icon: Icons.qr_code_2,
                      label: 'Saldo Billetera Digital',
                      amount: currency.format(digitalWalletBalance),
                      highlight: true,
                    ),
                    _BalancePill(
                      icon: Icons.payments_outlined,
                      label: 'Efectivo Hogar',
                      amount: currency.format(cashBalance),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text('Presupuestos por Categoría de Gasto',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...expenseCategories.map((c) {
          final spent = allTx
              .where((t) => t.type == 2 && t.categoryName == c.name)
              .fold(0.0, (s, t) => s + t.amount);
          final progress =
              c.monthlyBudget > 0 ? (spent / c.monthlyBudget).clamp(0.0, 1.0) : 0.0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold))),
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
                  Text(
                      '${currency.format(spent)} de ${currency.format(c.monthlyBudget)} • ${c.bucket503020}'),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        const Text('Filtro por Integrante del Hogar',
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
        const SizedBox(height: 16),

        TextField(
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
          decoration: InputDecoration(
            hintText: 'Buscar por descripción, categoría o billetera...',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        ...filteredTx.map((t) {
          final isInc = t.type == 1;
          final isTransfer = t.type == 3;
          final bgColor = isTransfer
              ? Colors.blue.shade100
              : (isInc ? Colors.green.shade100 : Colors.red.shade100);
          final fgColor = isTransfer
              ? Colors.blue.shade800
              : (isInc ? Colors.green.shade800 : Colors.red.shade800);
          final iconData = isTransfer
              ? Icons.swap_horiz
              : (isInc ? Icons.arrow_downward : Icons.arrow_upward);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: bgColor,
                child: Icon(iconData, color: fgColor),
              ),
              title: Text(t.description, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${t.categoryName} • ${t.accountName} • Por: ${t.memberName}'),
              trailing: Text(
                '${isTransfer ? '⇄ ' : (isInc ? '+' : '-')}${currency.format(t.amount)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: fgColor),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _BalancePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final bool highlight;

  const _BalancePill({
    required this.icon,
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.teal.shade800
            : Theme.of(context).colorScheme.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: highlight ? Colors.white : Colors.teal),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: highlight ? Colors.teal.shade100 : Colors.grey)),
              Text(amount,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: highlight ? Colors.white : null)),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PESTAÑA 2: PARAMETRIZACIÓN DE CUENTAS, BILLETERAS DIGITALES Y RUBROS
// ============================================================================
class CatalogsSettingsView extends ConsumerWidget {
  const CatalogsSettingsView({super.key});

  void _showAddAccountDialog(BuildContext context, WidgetRef ref,
      {String defaultType = 'Billetera Digital'}) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0');
    String selectedType = defaultType;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nueva Cuenta o Billetera Digital'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Opción de Saldo / Tipo de Cuenta',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Billetera Digital',
                    'Banco',
                    'Efectivo',
                    'Tarjeta de Crédito',
                    'Ahorro',
                    'Cooperativa'
                  ]
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(getAccountTypeIcon(t), size: 18, color: Colors.teal),
                                const SizedBox(width: 8),
                                Text(t),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: selectedType == 'Billetera Digital'
                        ? 'Nombre de la Billetera Digital'
                        : 'Nombre de la Cuenta',
                    hintText: selectedType == 'Billetera Digital'
                        ? 'Ej. Saldo Payphone, Deuna, Peigo...'
                        : 'Ej. Banco Pichincha, Produbanco...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Saldo Disponible Inicial (USD)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final bal = double.tryParse(balanceCtrl.text) ?? 0.0;
                final current = ref.read(accountsProvider);
                ref.read(accountsProvider.notifier).state = [
                  ...current,
                  AccountModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    type: selectedType,
                    balance: bal,
                  ),
                ];
                Navigator.pop(ctx);
              },
              child: const Text('Guardar Opción de Saldo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final categories = ref.watch(categoriesProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Parametrización de Cuentas, Billeteras Digitales y Rubros',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          children: [
            const Text('1. Cuentas Bancarias y Billeteras Digitales',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _showAddAccountDialog(context, ref, defaultType: 'Billetera Digital'),
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('+ Billetera Digital'),
                ),
                FilledButton.icon(
                  onPressed: () => _showAddAccountDialog(context, ref, defaultType: 'Banco'),
                  icon: const Icon(Icons.account_balance),
                  label: const Text('+ Cuenta Bancaria'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...accounts.map((a) {
          final isDigital = a.type == 'Billetera Digital';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isDigital ? Colors.teal : null,
                foregroundColor: isDigital ? Colors.white : null,
                child: Icon(getAccountTypeIcon(a.type)),
              ),
              title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Tipo: ${a.type} • Saldo: ${currency.format(a.balance)}'),
            ),
          );
        }),
        const SizedBox(height: 20),
        const Text('2. Categorías y Clasificación 50/30/20',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...categories.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(c.type == 1 ? Icons.trending_up : Icons.trending_down,
                    color: c.type == 1 ? Colors.green : Colors.red),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(c.type == 1
                    ? 'Categoría de Ingreso'
                    : 'Tope: ${currency.format(c.monthlyBudget)} • ${c.bucket503020}'),
              ),
            )),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 3 (NUEVA): COPILOTO IA REGLA 50/30/20 + SPLIT FAMILIAR + DETECTOR GASTOS HORMIGA + CSV
// ============================================================================
class Copiloto503020AndExportView extends ConsumerWidget {
  const Copiloto503020AndExportView({super.key});

  String _generateCsv(List<TxItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('Fecha,Tipo,Categoria,Descripcion,Cuenta_Billetera,Miembro,Monto_USD');
    for (final t in items) {
      final tipo = t.type == 1 ? 'INGRESO' : (t.type == 3 ? 'TRANSFERENCIA' : 'GASTO');
      final fecha = DateFormat('yyyy-MM-dd').format(t.date);
      buffer.writeln(
          '$fecha,$tipo,${t.categoryName},${t.description},${t.accountName},${t.memberName},${t.amount.toStringAsFixed(2)}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTx = ref.watch(transactionsListProvider);
    final categories = ref.watch(categoriesProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final income = allTx.where((t) => t.type == 1).fold(0.0, (s, t) => s + t.amount);
    final expenses = allTx.where((t) => t.type == 2).toList();
    final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);

    // Cálculo Regla 50/30/20
    double needsSpent = 0;
    double wantsSpent = 0;
    for (final e in expenses) {
      final cat = categories.where((c) => c.name == e.categoryName).firstOrNull;
      if (cat != null && cat.bucket503020.contains('30%')) {
        wantsSpent += e.amount;
      } else {
        needsSpent += e.amount;
      }
    }
    final savingsActual = (income - totalExpense).clamp(0.0, double.infinity);

    // Detector de Gastos Hormiga (compras <= $15)
    final microExpenses = expenses.where((e) => e.amount <= 15.0).toList();
    final microTotal = microExpenses.fold(0.0, (s, e) => s + e.amount);

    // División de Gastos Familiar (Split Equitativo entre Admin Hogar y Pareja)
    final adminPaid = expenses
        .where((e) => e.memberName == 'Admin Hogar')
        .fold(0.0, (s, e) => s + e.amount);
    final partnerPaid =
        expenses.where((e) => e.memberName == 'Pareja').fold(0.0, (s, e) => s + e.amount);
    final fairShare = (adminPaid + partnerPaid) / 2.0;
    final splitDiff = (adminPaid - fairShare).abs();

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
                  Text('Copiloto Financiero 50/30/20 & Split Familiar',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Diagnóstico inteligente de presupuesto, gastos hormiga y equidad familiar',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                final csv = _generateCsv(allTx);
                Clipboard.setData(ClipboardData(text: csv));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✓ Sábana contable CSV copiada para Excel / Google Sheets.')),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Exportar Excel / CSV'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 1. Diagnóstico Regla 50 / 30 / 20
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_Graph, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Diagnóstico Regla 50% Necesidades / 30% Deseos / 20% Ahorro',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                _RuleBar(
                  title: 'Necesidades Básicas (Meta ideal <= 50% de tus ingresos)',
                  amount: currency.format(needsSpent),
                  target: currency.format(income * 0.50),
                  ratio: income > 0 ? (needsSpent / (income * 0.50)).clamp(0.0, 1.0) : 0.0,
                  color: Colors.teal,
                ),
                const SizedBox(height: 12),
                _RuleBar(
                  title: 'Estilo de Vida, Ocio y Gastos Hormiga (Meta <= 30%)',
                  amount: currency.format(wantsSpent),
                  target: currency.format(income * 0.30),
                  ratio: income > 0 ? (wantsSpent / (income * 0.30)).clamp(0.0, 1.0) : 0.0,
                  color: Colors.amber.shade800,
                ),
                const SizedBox(height: 12),
                _RuleBar(
                  title: 'Ahorro Neto y Pago de Deudas (Meta mínima >= 20%)',
                  amount: currency.format(savingsActual),
                  target: currency.format(income * 0.20),
                  ratio: income > 0 ? (savingsActual / (income * 0.20)).clamp(0.0, 1.0) : 0.0,
                  color: Colors.green.shade700,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. División y Equidad de Gastos en Pareja / Familia (Splitwise Integrado)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.balance, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Liquidación y Equidad de Gastos del Hogar (Split 50/50)',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                    '• Pagado por Admin Hogar: ${currency.format(adminPaid)}\n'
                    '• Pagado por Pareja: ${currency.format(partnerPaid)}\n'
                    '• Cuota equitativa por miembro (50%): ${currency.format(fairShare)}',
                    style: const TextStyle(height: 1.5)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    adminPaid >= partnerPaid
                        ? '⚖️ Para quedar a mano este mes: Pareja debe transferir ${currency.format(splitDiff)} a la Billetera Digital de Admin Hogar.'
                        : '⚖️ Para quedar a mano este mes: Admin Hogar debe transferir ${currency.format(splitDiff)} a Pareja.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Detector de Gastos Hormiga
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Icon(Icons.bug_report, color: Colors.orange.shade900),
            ),
            title: const Text('Detector de "Gastos Hormiga" (Compras <= \$15)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Se detectaron ${microExpenses.length} micro-gastos este mes por ${currency.format(microTotal)}. Proyección de fuga anual: ${currency.format(microTotal * 12)}.'),
          ),
        ),
      ],
    );
  }
}

class _RuleBar extends StatelessWidget {
  final String title;
  final String amount;
  final String target;
  final double ratio;
  final Color color;

  const _RuleBar({
    required this.title,
    required this.amount,
    required this.target,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            Text('$amount / $target'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          minHeight: 9,
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 4 (NUEVA): TARJETAS DE CRÉDITO, DIFERIDOS (CUOTAS), METAS Y PAGOS FIJOS
// ============================================================================
class CreditCardsGoalsAndRecurringView extends ConsumerWidget {
  const CreditCardsGoalsAndRecurringView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final installments = ref.watch(installmentsProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final bills = ref.watch(recurringBillsProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Control de Tarjetas de Crédito y Compras Diferidas (Cuotas)
        const Text('Tarjetas de Crédito: Control de Diferidos y Fechas de Corte',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Seguimiento de compras en cuotas (3, 6, 12 meses) y saldo por vencer',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        ...installments.map((inst) {
          final progress = (inst.paidMonths / inst.totalMonths).clamp(0.0, 1.0);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${inst.cardName} • ${inst.description}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Chip(
                        label: Text(
                            'Corte: Día ${inst.cutOffDay} | Pago: Día ${inst.paymentDueDay}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, minHeight: 8),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Cuota Mensual: ${currency.format(inst.monthlyQuota)}  •  Pagadas: ${inst.paidMonths}/${inst.totalMonths} cuotas  •  Saldo Restante: ${currency.format(inst.remainingBalance)}'),
                      if (inst.paidMonths < inst.totalMonths)
                        FilledButton.tonal(
                          onPressed: () {
                            ref.read(installmentsProvider.notifier).state = installments
                                .map((item) => item.id == inst.id
                                    ? item.copyWith(paidMonths: item.paidMonths + 1)
                                    : item)
                                .toList();
                          },
                          child: const Text('Pagar Cuota'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),

        // 2. Metas de Ahorro Familiar
        const Text('Metas de Ahorro Familiar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...goals.map((g) {
          final pct = (g.currentAmount / g.targetAmount).clamp(0.0, 1.0);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(18),
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
        const SizedBox(height: 24),

        // 3. Pagos Fijos Mensuales
        const Text('Pagos Fijos y Suscripciones',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
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
// PESTAÑA 5: PASARELAS DE PAGO (PAYPHONE WEB + REVENUECAT MOBILE)
// ============================================================================
class MonetizationGatewaysView extends ConsumerWidget {
  const MonetizationGatewaysView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final previewMode = ref.watch(gatewayPreviewModeProvider);
    final isAnnual = sub.selectedBillingCycle == 'annual';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Pasarelas de Monetización: Payphone & RevenueCat',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'WEB_PAYPHONE',
              icon: Icon(Icons.language),
              label: Text('Canal Web: Payphone V2'),
            ),
            ButtonSegment(
              value: 'MOBILE_REVENUECAT',
              icon: Icon(Icons.phone_iphone),
              label: Text('Canal Móvil: RevenueCat'),
            ),
          ],
          selected: {previewMode},
          onSelectionChanged: (s) => ref.read(gatewayPreviewModeProvider.notifier).state = s.first,
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: Icon(sub.isPro ? Icons.verified : Icons.lock_outline,
                color: sub.isPro ? Colors.teal : Colors.grey, size: 32),
            title: Text(sub.planName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Pasarela: ${sub.gateway} • Auth: ${sub.lastAuthCode}'),
            trailing: Switch(
              value: sub.isPro,
              onChanged: (v) => ref.read(subscriptionProvider.notifier).state = sub.copyWith(
                isPro: v,
                planName: v ? 'Cash Pro Activo' : 'Plan Hogar Básico (Gratis)',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  previewMode == 'WEB_PAYPHONE'
                      ? 'Checkout Web con Payphone Business (Confirmación V2)'
                      : 'Suscripción Nativa con RevenueCat (Google Play / App Store)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  previewMode == 'WEB_PAYPHONE'
                      ? 'Acepta tarjetas Visa, Mastercard, Diners y Saldo de Billetera Payphone confirmando en /api/button/V2/Confirm.'
                      : 'Desbloquea el Entitlement "${BillingConfig.entitlementId}" sincronizado vía Webhook con PostgreSQL.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(subscriptionProvider.notifier).state = ActiveSubscriptionInfo(
                      isPro: true,
                      planName: isAnnual ? 'Cash Pro Anual (\$39.99)' : 'Cash Pro Mensual (\$4.99)',
                      gateway: previewMode == 'WEB_PAYPHONE'
                          ? 'Payphone Web V2'
                          : 'RevenueCat In-App Purchase',
                      lastAuthCode:
                          'AUTH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Suscripción Cash Pro activada.')),
                    );
                  },
                  icon: const Icon(Icons.payment),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Probar Cobro y Activar Cash Pro'),
                  ),
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
// MODAL DE REGISTRO: GASTO (2) | INGRESO (1) | RECARGAR BILLETERA / TRANSFERIR (3)
// ============================================================================
class NewTxModal extends ConsumerStatefulWidget {
  final int initialType;
  const NewTxModal({super.key, this.initialType = 2});
  @override
  ConsumerState<NewTxModal> createState() => _NewTxModalState();
}

class _NewTxModalState extends ConsumerState<NewTxModal> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  late int _type;
  String? _selectedCategory;
  String? _selectedAccount;
  String? _destinationAccount;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final accounts = ref.watch(accountsProvider);
    final allCategories = ref.watch(categoriesProvider);
    final filteredCategories =
        allCategories.where((c) => c.type == (_type == 1 ? 1 : 2)).toList();

    if (_selectedAccount == null || !accounts.any((a) => a.name == _selectedAccount)) {
      _selectedAccount = accounts.first.name;
    }
    if (_destinationAccount == null ||
        !accounts.any((a) => a.name == _destinationAccount) ||
        _destinationAccount == _selectedAccount) {
      final wallet = accounts.where((a) => a.type == 'Billetera Digital').firstOrNull;
      _destinationAccount = (wallet != null && wallet.name != _selectedAccount)
          ? wallet.name
          : (accounts.length > 1 ? accounts[1].name : accounts.first.name);
    }
    if (_selectedCategory == null ||
        !filteredCategories.any((c) => c.name == _selectedCategory)) {
      _selectedCategory = filteredCategories.first.name;
    }

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
          Text(
            _type == 3 ? 'Recargar Billetera Digital / Transferir' : 'Registrar Movimiento',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                  value: 2, label: Text('Gasto'), icon: Icon(Icons.remove_circle_outline)),
              ButtonSegment(
                  value: 1, label: Text('Ingreso'), icon: Icon(Icons.add_circle_outline)),
              ButtonSegment(
                  value: 3, label: Text('Recargar / Transf.'), icon: Icon(Icons.swap_horiz)),
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
            decoration: InputDecoration(
              labelText: _type == 3
                  ? 'Concepto (Ej. Recarga a Billetera Digital)'
                  : 'Descripción',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedAccount,
            decoration: InputDecoration(
              labelText: _type == 3
                  ? 'Cuenta Origen (De donde sale el saldo)'
                  : 'Opción de Saldo / Cuenta',
              border: const OutlineInputBorder(),
            ),
            items: accounts
                .map((a) => DropdownMenuItem(
                      value: a.name,
                      child: Text('${a.name} (${a.type})'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedAccount = v),
          ),
          const SizedBox(height: 12),
          if (_type == 3)
            DropdownButtonFormField<String>(
              value: _destinationAccount,
              decoration: const InputDecoration(
                labelText: 'Billetera o Cuenta Destino (A donde llega el saldo)',
                border: OutlineInputBorder(),
              ),
              items: accounts
                  .map((a) => DropdownMenuItem(
                        value: a.name,
                        child: Text('${a.name} (${a.type})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _destinationAccount = v),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: _type == 2 ? 'Categoría de Gasto' : 'Categoría de Ingreso',
                border: const OutlineInputBorder(),
              ),
              items: filteredCategories
                  .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final amt = double.tryParse(_amountCtrl.text) ?? 0;
              if (amt <= 0 || _selectedAccount == null) return;

              final list = ref.read(transactionsListProvider);

              if (_type == 3) {
                if (_destinationAccount == null || _destinationAccount == _selectedAccount) {
                  return;
                }
                ref.read(transactionsListProvider.notifier).state = [
                  TxItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    description: _descCtrl.text.isEmpty
                        ? 'Recarga / Transferencia de Saldo'
                        : _descCtrl.text,
                    amount: amt,
                    type: 3,
                    categoryName: 'Transferencia / Recarga',
                    accountName: '$_selectedAccount → $_destinationAccount',
                    memberName: session?.fullName ?? 'Hogar',
                  ),
                  ...list,
                ];

                ref.read(accountsProvider.notifier).state = accounts.map((acc) {
                  if (acc.name == _selectedAccount) {
                    return acc.copyWith(balance: acc.balance - amt);
                  }
                  if (acc.name == _destinationAccount) {
                    return acc.copyWith(balance: acc.balance + amt);
                  }
                  return acc;
                }).toList();
              } else {
                ref.read(transactionsListProvider.notifier).state = [
                  TxItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    description: _descCtrl.text.isEmpty ? 'Movimiento' : _descCtrl.text,
                    amount: amt,
                    type: _type,
                    categoryName: _selectedCategory!,
                    accountName: _selectedAccount!,
                    memberName: session?.fullName ?? 'Hogar',
                  ),
                  ...list,
                ];

                ref.read(accountsProvider.notifier).state = accounts.map((acc) {
                  if (acc.name == _selectedAccount) {
                    final delta = _type == 1 ? amt : -amt;
                    return acc.copyWith(balance: acc.balance + delta);
                  }
                  return acc;
                }).toList();
              }

              Navigator.pop(context);
            },
            child: Text(_type == 3 ? 'Ejecutar Recarga / Transferencia' : 'Guardar Movimiento'),
          ),
        ],
      ),
    );
  }
}
