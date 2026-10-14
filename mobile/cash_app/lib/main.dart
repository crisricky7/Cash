import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ProviderScope(child: CashApp()));
}

// ============================================================================
// UTILIDAD RESPONSIVA GLOBAL: MODAL ADAPTATIVO A PRUEBA DE TECLADO MÓVIL
// ============================================================================
Future<void> showAdaptiveSheetOrDialog({
  required BuildContext context,
  required Widget child,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 650) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  } else {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// MODELOS DE DOMINIO COMPLETOS
// ============================================================================
enum SubscriptionTier {
  personal(
    code: 'personal',
    title: 'Plan Personal',
    subtitle: 'Finanzas individuales y control total',
    maxUsers: 1,
    monthlyPrice: 1.99,
    annualPrice: 15.99,
    annualMonthlyEquivalent: 1.33,
    annualSavingsUsd: 7.89,
    revenueCatMonthlySku: 'cash_personal_monthly_199',
    revenueCatAnnualSku: 'cash_personal_annual_1599',
  ),
  familiar(
    code: 'familiar',
    title: 'Plan Familiar',
    subtitle: 'Hogar compartido hasta 4 integrantes',
    maxUsers: 4,
    monthlyPrice: 4.99,
    annualPrice: 39.99,
    annualMonthlyEquivalent: 3.33,
    annualSavingsUsd: 19.89,
    revenueCatMonthlySku: 'cash_familiar_monthly_499',
    revenueCatAnnualSku: 'cash_familiar_annual_3999',
  ),
  familiarPlus(
    code: 'familiar_plus',
    title: 'Plan Familiar Plus',
    subtitle: 'Familias grandes hasta 7 integrantes',
    maxUsers: 7,
    monthlyPrice: 7.99,
    annualPrice: 63.99,
    annualMonthlyEquivalent: 5.33,
    annualSavingsUsd: 31.89,
    revenueCatMonthlySku: 'cash_familiar_plus_monthly_799',
    revenueCatAnnualSku: 'cash_familiar_plus_annual_6399',
  );

  final String code;
  final String title;
  final String subtitle;
  final int maxUsers;
  final double monthlyPrice;
  final double annualPrice;
  final double annualMonthlyEquivalent;
  final double annualSavingsUsd;
  final String revenueCatMonthlySku;
  final String revenueCatAnnualSku;

  const SubscriptionTier({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.maxUsers,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.annualMonthlyEquivalent,
    required this.annualSavingsUsd,
    required this.revenueCatMonthlySku,
    required this.revenueCatAnnualSku,
  });
}

class AuthSession {
  final String fullName;
  final String email;
  final String role; // 'Usuario' | 'SuperAdmin'
  AuthSession({required this.fullName, required this.email, required this.role});

  bool get isSuperAdmin => role == 'SuperAdmin';
}

class HouseholdMember {
  final String id;
  final String name;
  final String email;
  final bool isOwner;
  HouseholdMember({
    required this.id,
    required this.name,
    required this.email,
    this.isOwner = false,
  });
}

class EmailInvitation {
  final String id;
  final String invitedName;
  final String invitedEmail;
  EmailInvitation({
    required this.id,
    required this.invitedName,
    required this.invitedEmail,
  });
}

class FinancialStoryTip {
  final String id;
  final String tag;
  final String title;
  final String body;
  final String actionTip;
  final List<Color> gradientColors;
  final bool isSeen;

  FinancialStoryTip({
    required this.id,
    required this.tag,
    required this.title,
    required this.body,
    required this.actionTip,
    required this.gradientColors,
    this.isSeen = false,
  });

  FinancialStoryTip copyWith({bool? isSeen}) => FinancialStoryTip(
        id: id,
        tag: tag,
        title: title,
        body: body,
        actionTip: actionTip,
        gradientColors: gradientColors,
        isSeen: isSeen ?? this.isSeen,
      );
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
  final String bucket503020; // Necesidades (50%) | Deseos / Estilo de Vida (30%) | Ahorro / Deudas (20%)
  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.monthlyBudget,
    this.bucket503020 = 'Necesidades (50%)',
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

// ============================================================================
// MOTOR INTELIGENTE DE LENGUAJE NATURAL (REGISTRO EN 3 SEGUNDOS)
// ============================================================================
class SmartInputParser {
  static ({
    double amount,
    String description,
    String category,
    String accountName,
    int type,
  })? parse(String rawText, List<AccountModel> accounts) {
    final text = rawText.trim();
    if (text.isEmpty) return null;

    final numRegex = RegExp(r'(\d+[.,]?\d*)');
    final match = numRegex.firstMatch(text);
    if (match == null) return null;

    final rawNum = match.group(1)!.replaceAll(',', '.');
    final amount = double.tryParse(rawNum) ?? 0.0;
    if (amount <= 0) return null;

    final cleanWords = text
        .replaceAll(match.group(0)!, '')
        .replaceAll('\$', '')
        .trim();

    final lower = text.toLowerCase();

    final isIncome = lower.contains('sueldo') ||
        lower.contains('ingreso') ||
        lower.contains('abono') ||
        lower.contains('cobro') ||
        lower.contains('salario');

    String selectedAccount = accounts.first.name;
    if (lower.contains('deuna') ||
        lower.contains('payphone') ||
        lower.contains('billetera') ||
        lower.contains('qr')) {
      final wallet = accounts.where((a) => a.type == 'Billetera Digital').firstOrNull;
      if (wallet != null) selectedAccount = wallet.name;
    } else if (lower.contains('efectivo') || lower.contains('caja') || lower.contains('cash')) {
      final cash = accounts.where((a) => a.type == 'Efectivo').firstOrNull;
      if (cash != null) selectedAccount = cash.name;
    }

    String category = isIncome ? 'Ingresos / Salario' : 'Supermercado y Alimentación';
    if (!isIncome) {
      if (lower.contains('taxi') ||
          lower.contains('uber') ||
          lower.contains('bus') ||
          lower.contains('gasolina')) {
        category = 'Transporte y Movilidad';
      } else if (lower.contains('luz') ||
          lower.contains('agua') ||
          lower.contains('internet') ||
          lower.contains('plan')) {
        category = 'Servicios Básicos (Luz/Agua/Net)';
      } else if (lower.contains('farmacia') ||
          lower.contains('medico') ||
          lower.contains('salud') ||
          lower.contains('colegio')) {
        category = 'Educación y Salud';
      } else if (lower.contains('cafe') ||
          lower.contains('cine') ||
          lower.contains('salida') ||
          lower.contains('pizza')) {
        category = 'Restaurantes, Salidas y Ocio';
      }
    }

    final finalDesc = cleanWords.isEmpty
        ? (isIncome ? 'Ingreso registrado' : category)
        : '${cleanWords[0].toUpperCase()}${cleanWords.substring(1)}';

    return (
      amount: amount,
      description: finalDesc,
      category: category,
      accountName: selectedAccount,
      type: isIncome ? 1 : 2,
    );
  }
}

// ============================================================================
// PROVIDERS GLOBALES (TODOS LOS MÓDULOS ACTIVOS)
// ============================================================================
final authSessionProvider = StateProvider<AuthSession?>((ref) => null);
final isDarkModeProvider = StateProvider<bool>((ref) => false);
final navIndexProvider = StateProvider<int>((ref) => 0);
final copilotSubTabProvider = StateProvider<int>((ref) => 0); // 0: Diferidos, 1: Metas, 2: 50/30/20 & CSV
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final subscriptionTierProvider =
    StateProvider<SubscriptionTier>((ref) => SubscriptionTier.personal);
final isAnnualBillingSelectedProvider = StateProvider<bool>((ref) => true);
final activeBillingCycleTextProvider =
    StateProvider<String>((ref) => 'Plan Personal (\$1.99 USD/mes)');

final householdMembersProvider = StateProvider<List<HouseholdMember>>((ref) => [
      HouseholdMember(
        id: 'm1',
        name: 'Titular de Cuenta',
        email: 'usuario@cash.com',
        isOwner: true,
      ),
    ]);

final pendingInvitationsProvider = StateProvider<List<EmailInvitation>>((ref) => []);

// REGLA AUTOMÁTICA: 1 persona = Modo Personal (false) | >1 personas = Modo Familiar (true)
final isFamilyModeProvider = Provider<bool>((ref) {
  final members = ref.watch(householdMembersProvider);
  return members.length > 1;
});

final storiesProvider = StateProvider<List<FinancialStoryTip>>((ref) => [
      FinancialStoryTip(
        id: 's1',
        tag: 'TIP OFICIAL CASH • 5 SEG',
        title: 'La Regla de las 24 Horas',
        body:
            'Antes de hacer una compra no planificada mayor a \$30, espera 24 horas. El 70% de las veces el impulso desaparece y ese dinero se queda en tu cuenta.',
        actionTip: 'Reto de hoy: Aplica esta pausa antes de comprar online.',
        gradientColors: const [Color(0xFF0D6E6E), Color(0xFF064E3B)],
        isSeen: false,
      ),
      FinancialStoryTip(
        id: 's2',
        tag: 'ECONOMÍA INTELIGENTE • 5 SEG',
        title: 'Recarga fija en tu Billetera Digital',
        body:
            'Transfiere cada lunes un monto fijo (ej. \$25) a tu Billetera Digital para cafés, snacks o pagos QR. Así blindas tu cuenta bancaria principal.',
        actionTip: 'Usa tus Billeteras Digitales como escudo para gastos diarios.',
        gradientColors: const [Color(0xFF0369A1), Color(0xFF1E3A8A)],
        isSeen: false,
      ),
      FinancialStoryTip(
        id: 's3',
        tag: 'PAZ MENTAL • 5 SEG',
        title: 'Separa tus Pagos Fijos el Día 1',
        body:
            'Apartar luz, internet y educación el primer día del mes reduce en un 80% el estrés financiero durante las siguientes 3 semanas.',
        actionTip: 'Tu métrica "Disponible hoy" ya protege tus pagos fijos.',
        gradientColors: const [Color(0xFF7C2D12), Color(0xFF9A3412)],
        isSeen: false,
      ),
    ]);

final accountsProvider = StateProvider<List<AccountModel>>((ref) => [
      AccountModel(id: 'a1', name: 'Cuenta Bancaria Principal', type: 'Banco', balance: 1850.00),
      AccountModel(
          id: 'a2',
          name: 'Billetera Digital (Payphone / Deuna)',
          type: 'Billetera Digital',
          balance: 195.00),
      AccountModel(id: 'a3', name: 'Efectivo Disponible', type: 'Efectivo', balance: 140.00),
      AccountModel(id: 'a4', name: 'Fondo de Reserva', type: 'Ahorro', balance: 3200.00),
    ]);

final categoriesProvider = StateProvider<List<CategoryModel>>((ref) => [
      CategoryModel(
        id: 'c1',
        name: 'Supermercado y Alimentación',
        type: 2,
        monthlyBudget: 600.00,
        bucket503020: 'Necesidades (50%)',
      ),
      CategoryModel(
        id: 'c2',
        name: 'Servicios Básicos (Luz/Agua/Net)',
        type: 2,
        monthlyBudget: 180.00,
        bucket503020: 'Necesidades (50%)',
      ),
      CategoryModel(
        id: 'c3',
        name: 'Educación y Salud',
        type: 2,
        monthlyBudget: 350.00,
        bucket503020: 'Necesidades (50%)',
      ),
      CategoryModel(
        id: 'c4',
        name: 'Transporte y Movilidad',
        type: 2,
        monthlyBudget: 150.00,
        bucket503020: 'Necesidades (50%)',
      ),
      CategoryModel(
        id: 'c5',
        name: 'Restaurantes, Salidas y Ocio',
        type: 2,
        monthlyBudget: 180.00,
        bucket503020: 'Deseos / Estilo de Vida (30%)',
      ),
      CategoryModel(
        id: 'c6',
        name: 'Ingresos / Salario',
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
        memberName: 'Titular de Cuenta',
        date: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      TxItem(
        id: 't2',
        description: 'Café y Panadería QR (Gasto Hormiga)',
        amount: 8.50,
        type: 2,
        categoryName: 'Restaurantes, Salidas y Ocio',
        accountName: 'Billetera Digital (Payphone / Deuna)',
        memberName: 'Titular de Cuenta',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TxItem(
        id: 't3',
        description: 'Recarga de Saldo a Billetera Digital',
        amount: 100.00,
        type: 3,
        categoryName: 'Transferencia / Recarga',
        accountName: 'Cuenta Bancaria Principal → Billetera Digital',
        memberName: 'Titular de Cuenta',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      TxItem(
        id: 't4',
        description: 'Ingreso Salario Mensual',
        amount: 2800.00,
        type: 1,
        categoryName: 'Ingresos / Salario',
        accountName: 'Cuenta Bancaria Principal',
        memberName: 'Titular de Cuenta',
        date: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ]);

final installmentsProvider = StateProvider<List<CreditInstallmentModel>>((ref) => [
      CreditInstallmentModel(
        id: 'i1',
        cardName: 'Visa Titanium',
        description: 'Refrigeradora Inverter (Diferido Sin Intereses)',
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
        title: 'Fondo de Emergencia (6 Meses)',
        targetAmount: 5000.00,
        currentAmount: 3200.00,
        deadline: 'Dic 2026',
      ),
      SavingsGoalModel(
        id: 'g2',
        title: 'Vacaciones Fin de Año',
        targetAmount: 1800.00,
        currentAmount: 950.00,
        deadline: 'Nov 2026',
      ),
    ]);

final recurringBillsProvider = StateProvider<List<RecurringBillModel>>((ref) => [
      RecurringBillModel(
        id: 'r1',
        title: 'Internet Fibra Óptica',
        category: 'Servicios Básicos (Luz/Agua/Net)',
        amount: 45.00,
        dueDay: 5,
        isPaid: true,
      ),
      RecurringBillModel(
        id: 'r2',
        title: 'Mensualidad / Educación',
        category: 'Educación y Salud',
        amount: 220.00,
        dueDay: 10,
        isPaid: false,
      ),
      RecurringBillModel(
        id: 'r3',
        title: 'Luz y Agua Potable',
        category: 'Servicios Básicos (Luz/Agua/Net)',
        amount: 55.00,
        dueDay: 18,
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
// COMPONENTE ICÓNICO: AVATAR CON ANILLO DE HISTORIAS ESTILO INSTAGRAM
// ============================================================================
class InstagramStoryLogoButton extends ConsumerWidget {
  final VoidCallback onTap;
  final double size;

  const InstagramStoryLogoButton({
    super.key,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesProvider);
    final hasUnseen = stories.any((s) => !s.isSeen);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(2.8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasUnseen
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFF59E0B),
                        Color(0xFFF43F5E),
                        Color(0xFFD946EF),
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    )
                  : null,
              border: hasUnseen
                  ? null
                  : Border.all(color: Colors.grey.withOpacity(0.45), width: 2),
              boxShadow: hasUnseen
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF43F5E).withOpacity(0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(
                  Icons.savings_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          if (hasUnseen)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  '5s',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// VISOR DE HISTORIAS DE 5 SEGUNDOS (SOLO EL SUPERADMIN VE EL BOTÓN DE SUBIR)
// ============================================================================
class StoryViewerModal extends ConsumerStatefulWidget {
  const StoryViewerModal({super.key});

  @override
  ConsumerState<StoryViewerModal> createState() => _StoryViewerModalState();
}

class _StoryViewerModalState extends ConsumerState<StoryViewerModal> {
  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stories = ref.read(storiesProvider);
      final firstUnseen = stories.indexWhere((s) => !s.isSeen);
      if (firstUnseen != -1) {
        setState(() => _currentIndex = firstUnseen);
      }
      _markCurrentAsSeen();
      _start5SecondTimer();
    });
  }

  void _markCurrentAsSeen() {
    final stories = ref.read(storiesProvider);
    if (_currentIndex >= 0 && _currentIndex < stories.length) {
      final targetId = stories[_currentIndex].id;
      ref.read(storiesProvider.notifier).state = stories
          .map((s) => s.id == targetId ? s.copyWith(isSeen: true) : s)
          .toList();
    }
  }

  void _start5SecondTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPaused || !mounted) return;
      setState(() {
        _progress += 0.01;
        if (_progress >= 1.0) {
          _nextStory();
        }
      });
    });
  }

  void _nextStory() {
    final stories = ref.read(storiesProvider);
    if (_currentIndex < stories.length - 1) {
      setState(() {
        _currentIndex++;
        _progress = 0.0;
      });
      _markCurrentAsSeen();
    } else {
      _timer?.cancel();
      if (mounted) Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progress = 0.0;
      });
      _markCurrentAsSeen();
    } else {
      setState(() => _progress = 0.0);
    }
  }

  void _openAdminCreateStorySheet() {
    setState(() => _isPaused = true);
    showAdaptiveSheetOrDialog(
      context: context,
      child: _AdminCreateStoryTipForm(
        onCreated: () {
          final stories = ref.read(storiesProvider);
          setState(() {
            _currentIndex = stories.length - 1;
            _progress = 0.0;
            _isPaused = false;
          });
          _markCurrentAsSeen();
        },
      ),
    ).then((_) {
      if (mounted) setState(() => _isPaused = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);
    final session = ref.watch(authSessionProvider);
    final isSuperAdmin = session?.isSuperAdmin ?? false;

    if (stories.isEmpty) return const SizedBox.shrink();

    final story = stories[_currentIndex.clamp(0, stories.length - 1)];
    final secondsLeft = ((1.0 - _progress) * 5).ceil().clamp(1, 5);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onLongPressStart: (_) => setState(() => _isPaused = true),
          onLongPressEnd: (_) => setState(() => _isPaused = false),
          onTapUp: (details) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            if (details.globalPosition.dx < screenWidth * 0.35) {
              _prevStory();
            } else {
              _nextStory();
            }
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: story.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: List.generate(stories.length, (index) {
                          double barValue = 0.0;
                          if (index < _currentIndex) {
                            barValue = 1.0;
                          } else if (index == _currentIndex) {
                            barValue = _progress.clamp(0.0, 1.0);
                          }
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: barValue,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.tips_and_updates,
                                    color: Colors.amberAccent, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    story.tag,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Cierra en ${secondsLeft}s',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (isSuperAdmin)
                                FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: _openAdminCreateStorySheet,
                                  icon: const Icon(Icons.admin_panel_settings, size: 16),
                                  label: const Text('Admin: +Tip 5s',
                                      style: TextStyle(fontSize: 11)),
                                ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.lightbulb_circle,
                                color: Colors.amberAccent, size: 54),
                            const SizedBox(height: 16),
                            Text(
                              story.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              story.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '💡 ${story.actionTip}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Toca a la izquierda o derecha para cambiar de historia',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminCreateStoryTipForm extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _AdminCreateStoryTipForm({required this.onCreated});

  @override
  ConsumerState<_AdminCreateStoryTipForm> createState() =>
      _AdminCreateStoryTipFormState();
}

class _AdminCreateStoryTipFormState extends ConsumerState<_AdminCreateStoryTipForm> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _actionCtrl = TextEditingController(text: 'Aplícalo hoy en tus finanzas.');
  int _selectedTheme = 0;

  final _themes = const [
    ('Verde Salvia (Armonía Familiar)', [Color(0xFF0D6E6E), Color(0xFF064E3B)]),
    ('Azul Océano (Control Personal)', [Color(0xFF0369A1), Color(0xFF1E3A8A)]),
    ('Ámbar Dorado (Ahorro Inteligente)', [Color(0xFFB45309), Color(0xFF78350F)]),
    ('Violeta Profundo (Inversión)', [Color(0xFF6D28D9), Color(0xFF4C1D95)]),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Consola SuperAdmin: Publicar Historia (5s)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Exclusivo para ti como administrador/desarrollador de Cash. Al publicar, todos los usuarios verán el anillo estilo Instagram iluminado.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Título del Tip (Ej. Compra al por mayor)',
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Consejo corto (Lectura de 5 segundos)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _actionCtrl,
          decoration: const InputDecoration(
            labelText: 'Reto o acción del día',
            prefixIcon: Icon(Icons.bolt),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _selectedTheme,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Color de Fondo de la Historia'),
          items: List.generate(
            _themes.length,
            (i) => DropdownMenuItem(value: i, child: Text(_themes[i].$1)),
          ),
          onChanged: (v) => setState(() => _selectedTheme = v!),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
                    return;
                  }
                  final current = ref.read(storiesProvider);
                  ref.read(storiesProvider.notifier).state = [
                    ...current,
                    FinancialStoryTip(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      tag: 'TIP OFICIAL CASH • 5 SEG',
                      title: _titleCtrl.text.trim(),
                      body: _bodyCtrl.text.trim(),
                      actionTip: _actionCtrl.text.trim(),
                      gradientColors: _themes[_selectedTheme].$2,
                      isSeen: false,
                    ),
                  ];
                  Navigator.pop(context);
                  widget.onCreated();
                },
                icon: const Icon(Icons.publish, size: 18),
                label: const Text('Publicar a Usuarios'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// APP PRINCIPAL: CAMBIO AUTOMÁTICO DE COLOR (1 USUARIO = PERSONAL | >1 = FAMILIAR)
// ============================================================================
class CashApp extends ConsumerWidget {
  const CashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final isFamily = ref.watch(isFamilyModeProvider);

    final seedColor = isFamily ? const Color(0xFF0D6E6E) : const Color(0xFF0369A1);
    final lightBg = isFamily ? const Color(0xFFF3F7F5) : const Color(0xFFF1F5F9);

    return MaterialApp(
      title: 'Cash · Finanzas Personales y Familiares',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: lightBg,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: session == null ? const LoginScreen() : const CompleteHomeShell(),
    );
  }
}

// ============================================================================
// PANTALLA DE LOGIN CON HUELLA BIOMÉTRICA + ROL CLIENTE vs DESARROLLADOR
// ============================================================================
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'usuario@cash.com');
  final _passCtrl = TextEditingController(text: 'Password123!');
  bool _scanningFingerprint = false;

  void _login(String name, String email, String role) {
    ref.read(authSessionProvider.notifier).state =
        AuthSession(fullName: name, email: email, role: role);
  }

  Future<void> _authenticateWithFingerprint() async {
    setState(() => _scanningFingerprint = true);
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _scanningFingerprint = false);
    final members = ref.read(householdMembersProvider);
    _login(members.first.name, members.first.email, 'Usuario');
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(householdMembersProvider);
    final isFamily = members.length > 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  InstagramStoryLogoButton(size: 64, onTap: () {}),
                  const SizedBox(height: 14),
                  const Text('Cash',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isFamily
                          ? 'Modo Familiar Activo (${members.length} integrantes)'
                          : 'Modo Personal Activo (1 integrante registrado)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _scanningFingerprint ? null : _authenticateWithFingerprint,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Column(
                          children: [
                            AnimatedScale(
                              scale: _scanningFingerprint ? 1.18 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.fingerprint,
                                  size: 42,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _scanningFingerprint
                                  ? 'Verificando huella digital...'
                                  : 'Ingresar con Huella Digital',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Acceso biométrico en 1 toque',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Correo Electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                _login('Titular de Cuenta', _emailCtrl.text, 'Usuario'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Entrar a mi Cuenta'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Seleccionar Perfil de Prueba:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: const Text('Entrar como Usuario / Cliente',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                          'Solo ve las historias de 5s. No puede subir historias.'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () =>
                          _login('Titular de Cuenta', 'usuario@cash.com', 'Usuario'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.amber.shade700),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.amber.shade700,
                        child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                      ),
                      title: const Text('Entrar como Desarrollador / SuperAdmin',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                          'Habilita la consola para cargar las historias diarias de 5s.'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _login(
                          'Cristhian (SuperAdmin App)', 'admin@cashapp.com', 'SuperAdmin'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SHELL PRINCIPAL DE 4 PESTAÑAS CON EL 100% DE LAS FUNCIONALIDADES
// ============================================================================
class CompleteHomeShell extends ConsumerWidget {
  const CompleteHomeShell({super.key});

  void _openStoryViewer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const StoryViewerModal(),
      ),
    );
  }

  void _openSuperAdminStoryCreator(BuildContext context) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: _AdminCreateStoryTipForm(
        onCreated: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    '✓ Historia oficial de 5s publicada. El anillo estilo Instagram ya está activo.')),
          );
        },
      ),
    );
  }

  void _openInvoiceScanner(BuildContext context) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: const SmartInvoiceScannerModal(),
    );
  }

  void _openManualForm(BuildContext context, {int initialType = 2}) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: ManualTxFormModal(initialType: initialType),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final navIdx = ref.watch(navIndexProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final isFamily = ref.watch(isFamilyModeProvider);
    final members = ref.watch(householdMembersProvider);
    final stories = ref.watch(storiesProvider);
    final unseenCount = stories.where((s) => !s.isSeen).length;
    final isSuperAdmin = session?.isSuperAdmin ?? false;

    final pages = [
      const TodayDashboardView(),
      const WalletsAndCatalogsView(),
      const CopilotCardsAndGoalsView(),
      const FamilyInvitationsAndPlansView(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 12,
            title: Row(
              children: [
                InstagramStoryLogoButton(
                  size: 42,
                  onTap: () => _openStoryViewer(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openStoryViewer(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Cash',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: unseenCount > 0
                                      ? const Color(0xFFF43F5E).withOpacity(0.14)
                                      : Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unseenCount > 0
                                      ? '● $unseenCount Tips de 5s'
                                      : 'Tips del Día (5s)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: unseenCount > 0
                                        ? const Color(0xFFE11D48)
                                        : Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isFamily
                              ? 'Modo Familiar Automático (${members.length} miembros)'
                              : 'Modo Personal Automático (1 usuario)',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              // Botón de Escáner de Facturas XML/OCR siempre a un toque en el AppBar
              IconButton(
                tooltip: 'Escanear Factura XML / OCR (IVA 15% & Deducibles)',
                icon: const Icon(Icons.document_scanner_outlined),
                onPressed: () => _openInvoiceScanner(context),
              ),
              // Consola de Historias exclusiva para el Desarrollador / SuperAdmin
              if (isSuperAdmin)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _openSuperAdminStoryCreator(context),
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    label: const Text('+ Subir Tip 5s', style: TextStyle(fontSize: 11)),
                  ),
                ),
              IconButton(
                tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => ref.read(isDarkModeProvider.notifier).state = !isDark,
              ),
              IconButton(
                tooltip: 'Cambiar perfil / Bloquear con Huella',
                icon: const Icon(Icons.lock_outline),
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
                      icon: Icon(Icons.wb_sunny_outlined),
                      selectedIcon: Icon(Icons.wb_sunny),
                      label: Text('Hoy & Facturas OCR'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet),
                      label: Text('Billeteras & Rubros'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.insights_outlined),
                      selectedIcon: Icon(Icons.insights),
                      label: Text('Diferidos, Metas & 50/30/20'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.group_add_outlined),
                      selectedIcon: Icon(Icons.group_add),
                      label: Text('Familia & Planes USD'),
                    ),
                  ],
                ),
              if (isWide) const VerticalDivider(width: 1),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
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
                    NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), label: 'Hoy'),
                    NavigationDestination(
                        icon: Icon(Icons.account_balance_wallet_outlined), label: 'Billeteras'),
                    NavigationDestination(
                        icon: Icon(Icons.insights_outlined), label: 'Copiloto'),
                    NavigationDestination(
                        icon: Icon(Icons.group_add_outlined), label: 'Familia & Plan'),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openManualForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Registrar'),
          ),
        );
      },
    );
  }
}

// ============================================================================
// MODAL RESTAURADO: ESCÁNER INTELIGENTE DE FACTURAS (OCR / XML SRI + IVA 15%)
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
    final members = ref.watch(householdMembersProvider);
    final total = double.tryParse(_totalCtrl.text) ?? 0.0;
    final subTotal = total / 1.15;
    final iva15 = total - subTotal;

    final lower = _merchantCtrl.text.toLowerCase();
    final detectedCategory = lower.contains('super') || lower.contains('maxi')
        ? 'Supermercado y Alimentación'
        : lower.contains('farmacia') || lower.contains('salud') || lower.contains('fybeca')
            ? 'Educación y Salud'
            : 'Servicios Básicos (Luz/Agua/Net)';

    final deductibleTag = detectedCategory == 'Supermercado y Alimentación'
        ? 'Rubro Deducible SRI: Alimentación'
        : detectedCategory == 'Educación y Salud'
            ? 'Rubro Deducible SRI: Salud / Educación'
            : 'Rubro Deducible SRI: Vivienda';

    if (!accounts.any((a) => a.name == _selectedAccount)) {
      _selectedAccount = accounts.first.name;
    }

    return Column(
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
                  Text('Escáner de Factura (XML / OCR)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Desglosa IVA 15% y clasifica gastos deducibles',
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
              label: const Text('Demo: Supermaxi (\$115)'),
              onPressed: () => setState(() {
                _merchantCtrl.text = 'Corporación Favorita - Supermaxi';
                _totalCtrl.text = '115.00';
              }),
            ),
            ActionChip(
              avatar: const Icon(Icons.local_pharmacy, size: 16),
              label: const Text('Demo: Fybeca (\$46)'),
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
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedAccount,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Pagado con (Cuenta o Billetera)'),
          items: accounts
              .map((a) => DropdownMenuItem(
                    value: a.name,
                    child: Text('${a.name} (${a.type})', overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedAccount = v!),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Subtotal: \$${subTotal.toStringAsFixed(2)}  •  IVA (15%): \$${iva15.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Categoría IA: $detectedCategory', style: const TextStyle(fontSize: 12)),
              Text('✓ $deductibleTag',
                  style: const TextStyle(
                      color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (total <= 0) return;
                  final list = ref.read(transactionsListProvider);
                  ref.read(transactionsListProvider.notifier).state = [
                    TxItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      description:
                          'Factura: ${_merchantCtrl.text} (IVA: \$${iva15.toStringAsFixed(2)})',
                      amount: total,
                      type: 2,
                      categoryName: detectedCategory,
                      accountName: _selectedAccount,
                      memberName: members.first.name,
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
                        content: Text('✓ Factura importada y descontada del saldo.')),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Importar Factura'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 1: "HOY" (BARRA MÁGICA 3S + ESCÁNER FACTURAS + DESGLOSE BILLETERA + FILTROS)
// ============================================================================
class TodayDashboardView extends ConsumerStatefulWidget {
  const TodayDashboardView({super.key});
  @override
  ConsumerState<TodayDashboardView> createState() => _TodayDashboardViewState();
}

class _TodayDashboardViewState extends ConsumerState<TodayDashboardView> {
  final _magicInputCtrl = TextEditingController();
  String? _selectedAuthor;

  void _executeMagicInput(String rawInput) {
    final accounts = ref.read(accountsProvider);
    final members = ref.read(householdMembersProvider);
    final parsed = SmartInputParser.parse(rawInput, accounts);

    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un concepto y un monto. Ejemplo: "Almuerzo 8.50 deuna"'),
        ),
      );
      return;
    }

    final author = _selectedAuthor ?? members.first.name;
    final txList = ref.read(transactionsListProvider);
    ref.read(transactionsListProvider.notifier).state = [
      TxItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: parsed.description,
        amount: parsed.amount,
        type: parsed.type,
        categoryName: parsed.category,
        accountName: parsed.accountName,
        memberName: author,
      ),
      ...txList,
    ];

    ref.read(accountsProvider.notifier).state = accounts.map((acc) {
      if (acc.name == parsed.accountName) {
        final delta = parsed.type == 1 ? parsed.amount : -parsed.amount;
        return acc.copyWith(balance: acc.balance + delta);
      }
      return acc;
    }).toList();

    _magicInputCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✓ Anotado por $author: ${parsed.description} (\$${parsed.amount.toStringAsFixed(2)} USD)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final allTx = ref.watch(transactionsListProvider);
    final bills = ref.watch(recurringBillsProvider);
    final members = ref.watch(householdMembersProvider);
    final isFamily = ref.watch(isFamilyModeProvider);
    final selectedMember = ref.watch(selectedMemberFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    if (_selectedAuthor == null || !members.any((m) => m.name == _selectedAuthor)) {
      _selectedAuthor = members.first.name;
    }

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

    final pendingBills =
        bills.where((b) => !b.isPaid).fold(0.0, (s, b) => s + b.amount);
    final freeMonthMoney = (totalBalance - pendingBills).clamp(0.0, double.infinity);

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final remainingDays = (daysInMonth - now.day + 1).clamp(1, 31);
    final safeToSpendToday = freeMonthMoney / remainingDays;

    final txAuthors = allTx.where((t) => t.type == 2).map((t) => t.memberName).toSet().toList();
    final filteredTx = allTx.where((t) {
      final matchesMember = selectedMember == null || t.memberName == selectedMember;
      final matchesSearch = searchQuery.isEmpty ||
          t.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.categoryName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.accountName.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesMember && matchesSearch;
    }).toList();

    final quickPresets = [
      ('☕ Café / Snack \$3.50', 'Café y Snack 3.50 deuna'),
      ('🚕 Taxi / Uber \$4.50', 'Taxi 4.50 efectivo'),
      ('🍔 Almuerzo \$8.00', 'Almuerzo 8.00 deuna'),
      ('🛒 Tienda \$15.00', 'Compra Tienda 15.00 efectivo'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      children: [
        // 1. TARJETA PRINCIPAL: DISPONIBLE PARA HOY + SALUD FINANCIERA + DESGLOSE BILLETERA DIGITAL
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFamily
                              ? 'Disponible para gastar hoy en familia:'
                              : 'Disponible para gastar hoy con tranquilidad:',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(safeToSpendToday),
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          children: [
                            Text('▲ Ingresos: ${currency.format(income)}',
                                style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            Text('▼ Gastos: ${currency.format(expense)}',
                                style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('Salud Financiera',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('$healthScore / 100',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                          Text('Ahorro: ${savingsRate.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22),
                // Desglose por tipo de saldo (Bancos vs Billetera Digital vs Efectivo)
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
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
                      label: 'Efectivo Disponible',
                      amount: currency.format(cashBalance),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. BARRA MÁGICA DE 3 SEGUNDOS + ACCESO A ESCÁNER DE FACTURAS XML/OCR
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.teal, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Registro Rápido en 3 Segundos',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFamily)
                          DropdownButton<String>(
                            value: _selectedAuthor,
                            underline: const SizedBox.shrink(),
                            isDense: true,
                            items: members
                                .map((m) => DropdownMenuItem(
                                      value: m.name,
                                      child: Text('Por: ${m.name}',
                                          style: const TextStyle(fontSize: 12)),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedAuthor = v),
                          ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          onPressed: () => showAdaptiveSheetOrDialog(
                            context: context,
                            child: const SmartInvoiceScannerModal(),
                          ),
                          icon: const Icon(Icons.document_scanner_outlined, size: 16),
                          label: const Text('Escanear Factura', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _magicInputCtrl,
                        onSubmitted: _executeMagicInput,
                        decoration: const InputDecoration(
                          hintText: 'Ej: "Almuerzo 8.50 deuna" o "Taxi 4 efectivo"',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _executeMagicInput(_magicInputCtrl.text),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Icon(Icons.send, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: quickPresets
                        .map((p) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(p.$1, style: const TextStyle(fontSize: 12)),
                                onPressed: () => _executeMagicInput(p.$2),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 3. BUSCADOR Y FILTRO POR INTEGRANTE
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Historial de Movimientos',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('${filteredTx.length} registros',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        if (txAuthors.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: Text('Todos (${currency.format(expense)})'),
                selected: selectedMember == null,
                onSelected: (_) =>
                    ref.read(selectedMemberFilterProvider.notifier).state = null,
              ),
              ...txAuthors.map((m) {
                final mSpent = allTx
                    .where((t) => t.type == 2 && t.memberName == m)
                    .fold(0.0, (s, t) => s + t.amount);
                return ChoiceChip(
                  label: Text('$m (${currency.format(mSpent)})'),
                  selected: selectedMember == m,
                  onSelected: (_) =>
                      ref.read(selectedMemberFilterProvider.notifier).state = m,
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
          decoration: const InputDecoration(
            hintText: 'Buscar por descripción, categoría o billetera...',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        ...filteredTx.map((t) {
          final isInc = t.type == 1;
          final isTransfer = t.type == 3;
          final fgColor = isTransfer
              ? Colors.blue.shade700
              : (isInc ? Colors.green.shade700 : Colors.red.shade700);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: fgColor.withOpacity(0.12),
                child: Icon(
                  isTransfer
                      ? Icons.swap_horiz
                      : (isInc ? Icons.arrow_downward : Icons.arrow_upward),
                  color: fgColor,
                  size: 18,
                ),
              ),
              title: Text(t.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${t.categoryName} • ${t.accountName} • ${t.memberName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                '${isTransfer ? '⇄ ' : (isInc ? '+' : '-')}${currency.format(t.amount)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: fgColor),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.teal.shade800
            : Theme.of(context).colorScheme.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: highlight ? Colors.white : Colors.teal),
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
                      fontSize: 14,
                      color: highlight ? Colors.white : null)),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PESTAÑA 2: BILLETERAS DIGITALES, CUENTAS, PAGOS FIJOS Y PARAMETRIZACIÓN DE RUBROS
// ============================================================================
class WalletsAndCatalogsView extends ConsumerWidget {
  const WalletsAndCatalogsView({super.key});

  void _openAddAccountModal(BuildContext context, {String defaultType = 'Billetera Digital'}) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: _AddAccountForm(defaultType: defaultType),
    );
  }

  void _openAddCategoryModal(BuildContext context, {int defaultType = 2}) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: _AddCategoryForm(defaultType: defaultType),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final categories = ref.watch(categoriesProvider);
    final bills = ref.watch(recurringBillsProvider);
    final allTx = ref.watch(transactionsListProvider);
    final expenseCats = categories.where((c) => c.type == 2).toList();
    final incomeCats = categories.where((c) => c.type == 1).toList();
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      children: [
        // 1. CUENTAS BANCARIAS Y BILLETERAS DIGITALES
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('1. Cuentas y Billeteras Digitales',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _openAddAccountModal(context, defaultType: 'Billetera Digital'),
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('+ Billetera Digital'),
                ),
                FilledButton.icon(
                  onPressed: () => _openAddAccountModal(context, defaultType: 'Banco'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+ Cuenta'),
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
                child: Icon(getAccountTypeIcon(a.type), size: 20),
              ),
              title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Opción de Saldo: ${a.type} • ${currency.format(a.balance)}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: accounts.length <= 1
                    ? null
                    : () {
                        ref.read(accountsProvider.notifier).state =
                            accounts.where((item) => item.id != a.id).toList();
                      },
              ),
            ),
          );
        }),
        const SizedBox(height: 22),

        // 2. PAGOS FIJOS DEL MES
        const Text('2. Pagos Fijos y Suscripciones del Mes',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...bills.map((b) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(b.isPaid ? Icons.check_circle : Icons.schedule,
                    color: b.isPaid ? Colors.green : Colors.amber.shade800),
                title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Vence el día ${b.dueDay} • ${currency.format(b.amount)}'),
                trailing: b.isPaid
                    ? const Chip(label: Text('Pagado'))
                    : FilledButton.tonal(
                        onPressed: () {
                          ref.read(recurringBillsProvider.notifier).state = bills
                              .map((item) =>
                                  item.id == b.id ? item.copyWith(isPaid: true) : item)
                              .toList();
                        },
                        child: const Text('Marcar Pagado'),
                      ),
              ),
            )),
        const SizedBox(height: 22),

        // 3. PARAMETRIZACIÓN DE TIPOS DE GASTOS Y PRESUPUESTOS
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('3. Tipos de Gastos y Presupuestos Mensuales',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            FilledButton.tonalIcon(
              onPressed: () => _openAddCategoryModal(context, defaultType: 2),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ Rubro de Gasto'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...expenseCats.map((c) {
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
                  Text('${currency.format(spent)} / ${currency.format(c.monthlyBudget)}',
                      style: const TextStyle(fontSize: 12)),
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
                  Text(c.bucket503020, style: const TextStyle(fontSize: 11)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: expenseCats.length <= 1
                    ? null
                    : () {
                        ref.read(categoriesProvider.notifier).state =
                            categories.where((item) => item.id != c.id).toList();
                      },
              ),
            ),
          );
        }),
        const SizedBox(height: 22),

        // 4. PARAMETRIZACIÓN DE TIPOS DE INGRESOS
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('4. Tipos de Ingresos',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            FilledButton.tonalIcon(
              onPressed: () => _openAddCategoryModal(context, defaultType: 1),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ Rubro de Ingreso'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...incomeCats.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.trending_up, color: Colors.green.shade800, size: 18),
                ),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Categoría de Ingreso Activa'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: incomeCats.length <= 1
                      ? null
                      : () {
                          ref.read(categoriesProvider.notifier).state =
                              categories.where((item) => item.id != c.id).toList();
                        },
                ),
              ),
            )),
      ],
    );
  }
}

class _AddAccountForm extends ConsumerStatefulWidget {
  final String defaultType;
  const _AddAccountForm({required this.defaultType});

  @override
  ConsumerState<_AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends ConsumerState<_AddAccountForm> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
  }

  @override
  Widget build(BuildContext context) {
    final isDigital = _selectedType == 'Billetera Digital';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Nueva Cuenta o Billetera Digital',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedType,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Opción de Saldo / Tipo'),
          items: [
            'Billetera Digital',
            'Banco',
            'Efectivo',
            'Tarjeta de Crédito',
            'Ahorro',
            'Cooperativa'
          ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _selectedType = v!),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText:
                isDigital ? 'Nombre de la Billetera Digital' : 'Nombre de la Cuenta',
            hintText: isDigital ? 'Ej. Payphone, Deuna, Peigo...' : 'Ej. Banco Pichincha...',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _balanceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Saldo Disponible Inicial (USD)',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  final bal = double.tryParse(_balanceCtrl.text) ?? 0.0;
                  final current = ref.read(accountsProvider);
                  ref.read(accountsProvider.notifier).state = [
                    ...current,
                    AccountModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameCtrl.text.trim(),
                      type: _selectedType,
                      balance: bal,
                    ),
                  ];
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddCategoryForm extends ConsumerStatefulWidget {
  final int defaultType;
  const _AddCategoryForm({required this.defaultType});

  @override
  ConsumerState<_AddCategoryForm> createState() => _AddCategoryFormState();
}

class _AddCategoryFormState extends ConsumerState<_AddCategoryForm> {
  final _nameCtrl = TextEditingController();
  late final TextEditingController _budgetCtrl;
  late int _selectedType;
  String _selectedBucket = 'Necesidades (50%)';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultType;
    _budgetCtrl = TextEditingController(text: widget.defaultType == 2 ? '200' : '0');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Parametrizar Rubro de Ingreso / Gasto',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 2, label: Text('Gasto'), icon: Icon(Icons.trending_down)),
            ButtonSegment(value: 1, label: Text('Ingreso'), icon: Icon(Icons.trending_up)),
          ],
          selected: {_selectedType},
          onSelectionChanged: (s) => setState(() => _selectedType = s.first),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText:
                _selectedType == 2 ? 'Nombre del Rubro de Gasto' : 'Nombre del Rubro de Ingreso',
          ),
        ),
        if (_selectedType == 2) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _budgetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Presupuesto Mensual Tope (USD)',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedBucket,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Clasificación Regla 50/30/20'),
            items: [
              'Necesidades (50%)',
              'Deseos / Estilo de Vida (30%)',
              'Ahorro / Deudas (20%)',
            ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) => setState(() => _selectedBucket = v!),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (_nameCtrl.text.trim().isEmpty) return;
                  final budget =
                      _selectedType == 2 ? (double.tryParse(_budgetCtrl.text) ?? 0.0) : 0.0;
                  final current = ref.read(categoriesProvider);
                  ref.read(categoriesProvider.notifier).state = [
                    ...current,
                    CategoryModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameCtrl.text.trim(),
                      type: _selectedType,
                      monthlyBudget: budget,
                      bucket503020: _selectedBucket,
                    ),
                  ];
                  Navigator.pop(context);
                },
                child: const Text('Guardar Rubro'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 3 RESTAURADA: DIFERIDOS DE TARJETAS, METAS DE AHORRO, COPILOTO 50/30/20 & EXCEL CSV
// ============================================================================
class CopilotCardsAndGoalsView extends ConsumerWidget {
  const CopilotCardsAndGoalsView({super.key});

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
    final subTab = ref.watch(copilotSubTabProvider);
    final installments = ref.watch(installmentsProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final allTx = ref.watch(transactionsListProvider);
    final categories = ref.watch(categoriesProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final income = allTx.where((t) => t.type == 1).fold(0.0, (s, t) => s + t.amount);
    final expenses = allTx.where((t) => t.type == 2).toList();
    final totalExpense = expenses.fold(0.0, (s, e) => s + e.amount);

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

    final microExpenses = expenses.where((e) => e.amount <= 15.0).toList();
    final microTotal = microExpenses.fold(0.0, (s, e) => s + e.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      children: [
        // Sub-navegación limpia para que todo esté disponible sin saturar la vista
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              icon: Icon(Icons.credit_score, size: 18),
              label: Text('Tarjetas y Diferidos'),
            ),
            ButtonSegment(
              value: 1,
              icon: Icon(Icons.savings_outlined, size: 18),
              label: Text('Metas de Ahorro'),
            ),
            ButtonSegment(
              value: 2,
              icon: Icon(Icons.auto_graph, size: 18),
              label: Text('50/30/20 & CSV'),
            ),
          ],
          selected: {subTab},
          onSelectionChanged: (s) => ref.read(copilotSubTabProvider.notifier).state = s.first,
        ),
        const SizedBox(height: 18),

        // SUB-VISTA 0: TARJETAS DE CRÉDITO Y DIFERIDOS (CUOTAS)
        if (subTab == 0) ...[
          const Text('Control de Tarjetas de Crédito y Compras Diferidas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Seguimiento de cuotas mensuales, fechas de corte y fechas de pago',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          ...installments.map((inst) {
            final progress = (inst.paidMonths / inst.totalMonths).clamp(0.0, 1.0);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${inst.cardName} • ${inst.description}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                              'Corte: Día ${inst.cutOffDay} | Pago: Día ${inst.paymentDueDay}',
                              style: const TextStyle(fontSize: 11)),
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text('Cuota: ${currency.format(inst.monthlyQuota)}/mes',
                              style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress, minHeight: 8),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Pagadas: ${inst.paidMonths}/${inst.totalMonths} cuotas • Saldo restante: ${currency.format(inst.remainingBalance)}',
                          style: const TextStyle(fontSize: 13),
                        ),
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
        ],

        // SUB-VISTA 1: METAS DE AHORRO FAMILIAR
        if (subTab == 1) ...[
          const Text('Metas de Ahorro',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Objetivos financieros con seguimiento de progreso y abonos rápidos',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          ...goals.map((g) {
            final pct = (g.currentAmount / g.targetAmount).clamp(0.0, 1.0);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(g.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(g.deadline, style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: pct, minHeight: 9),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                            'Ahorrado: ${currency.format(g.currentAmount)} de ${currency.format(g.targetAmount)} (${(pct * 100).toInt()}%)'),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            ref.read(savingsGoalsProvider.notifier).state = goals
                                .map((item) => item.id == g.id
                                    ? item.copyWith(currentAmount: item.currentAmount + 100)
                                    : item)
                                .toList();
                          },
                          icon: const Icon(Icons.add, size: 16),
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

        // SUB-VISTA 2: COPILOTO 50/30/20, GASTOS HORMIGA & EXPORTACIÓN EXCEL / CSV
        if (subTab == 2) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Diagnóstico 50/30/20 & Exportación Contable',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Evaluación inteligente de tus finanzas y descarga para Excel',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              FilledButton.icon(
                onPressed: () {
                  final csv = _generateCsv(allTx);
                  Clipboard.setData(ClipboardData(text: csv));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('✓ Sábana contable CSV copiada para Excel / Google Sheets.')),
                  );
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Exportar Excel / CSV'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Regla 50% Necesidades / 30% Deseos / 20% Ahorro',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  _RuleBar(
                    title: 'Necesidades Básicas (Meta <= 50%)',
                    amount: currency.format(needsSpent),
                    target: currency.format(income * 0.50),
                    ratio: income > 0 ? (needsSpent / (income * 0.50)).clamp(0.0, 1.0) : 0.0,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 12),
                  _RuleBar(
                    title: 'Estilo de Vida y Ocio (Meta <= 30%)',
                    amount: currency.format(wantsSpent),
                    target: currency.format(income * 0.30),
                    ratio: income > 0 ? (wantsSpent / (income * 0.30)).clamp(0.0, 1.0) : 0.0,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(height: 12),
                  _RuleBar(
                    title: 'Ahorro Neto Disponible (Meta >= 20%)',
                    amount: currency.format(savingsActual),
                    target: currency.format(income * 0.20),
                    ratio: income > 0
                        ? (savingsActual / (income * 0.20)).clamp(0.0, 1.0)
                        : 0.0,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Icon(Icons.bug_report, color: Colors.orange.shade900),
              ),
              title: const Text('Detector de "Gastos Hormiga" (Compras <= \$15)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Se detectaron ${microExpenses.length} micro-gastos este mes (${currency.format(microTotal)}). Fuga anual proyectada: ${currency.format(microTotal * 12)}.'),
            ),
          ),
        ],
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
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text('$amount / $target', style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio,
          minHeight: 8,
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 4: INVITACIONES POR CORREO & 3 PLANES EN USD (MENSUAL Y ANUAL -33%)
// ============================================================================
class FamilyInvitationsAndPlansView extends ConsumerStatefulWidget {
  const FamilyInvitationsAndPlansView({super.key});

  @override
  ConsumerState<FamilyInvitationsAndPlansView> createState() =>
      _FamilyInvitationsAndPlansViewState();
}

class _FamilyInvitationsAndPlansViewState
    extends ConsumerState<FamilyInvitationsAndPlansView> {
  final _inviteNameCtrl = TextEditingController();
  final _inviteEmailCtrl = TextEditingController();

  void _sendEmailInvitation() {
    final name = _inviteNameCtrl.text.trim();
    final email = _inviteEmailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ingresa el nombre y un correo electrónico válido del familiar.')),
      );
      return;
    }

    final currentTier = ref.read(subscriptionTierProvider);
    final activeMembers = ref.read(householdMembersProvider);
    final pendingInvites = ref.read(pendingInvitationsProvider);
    final totalUsedOrPending = activeMembers.length + pendingInvites.length;

    if (totalUsedOrPending >= currentTier.maxUsers) {
      showAdaptiveSheetOrDialog(
        context: context,
        child: _UpgradeTierPromptSheet(currentTier: currentTier),
      );
      return;
    }

    ref.read(pendingInvitationsProvider.notifier).state = [
      ...pendingInvites,
      EmailInvitation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        invitedName: name,
        invitedEmail: email,
      ),
    ];

    _inviteNameCtrl.clear();
    _inviteEmailCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✉️ Correo de invitación enviado a $email. Cuando lo acepte, se sumará a tu familia automáticamente.'),
      ),
    );
  }

  void _acceptEmailInvitation(EmailInvitation inv) {
    final members = ref.read(householdMembersProvider);
    final pending = ref.read(pendingInvitationsProvider);

    ref.read(pendingInvitationsProvider.notifier).state =
        pending.where((i) => i.id != inv.id).toList();

    ref.read(householdMembersProvider.notifier).state = [
      ...members,
      HouseholdMember(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: inv.invitedName,
        email: inv.invitedEmail,
      ),
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '🎉 ${inv.invitedName} aceptó el correo. ¡Se agregó a tu familia y el Modo Familiar se activó automáticamente!'),
      ),
    );
  }

  void _openCheckoutForTier(SubscriptionTier targetTier, bool isAnnual) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: _TierCheckoutSheet(targetTier: targetTier, initialIsAnnual: isAnnual),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(householdMembersProvider);
    final pendingInvites = ref.watch(pendingInvitationsProvider);
    final currentTier = ref.watch(subscriptionTierProvider);
    final isAnnualSelected = ref.watch(isAnnualBillingSelectedProvider);
    final isFamily = ref.watch(isFamilyModeProvider);
    final activeBillingText = ref.watch(activeBillingCycleTextProvider);
    final allTx = ref.watch(transactionsListProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final expenses = allTx.where((t) => t.type == 2).toList();
    final totalSharedExpense = expenses.fold(0.0, (s, e) => s + e.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      children: [
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isFamily ? Icons.diversity_3 : Icons.person_pin,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isFamily
                            ? 'Modo Familiar Activo Automáticamente (${members.length} personas)'
                            : 'Modo Personal Activo Automáticamente (1 sola persona)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isFamily
                      ? 'Como tienes más de 1 integrante compartiendo ingresos y gastos, la app usa la paleta Verde Salvia Familiar y habilita el reparto equitativo del hogar.'
                      : 'Como solo hay 1 persona registrada, la app opera en Modo Personal (Azul Océano). Invita a un familiar por correo y cuando acepte pasará a Modo Familiar automáticamente.',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text('Invitar Integrante a la Familia por Correo',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        'Cupos: ${members.length}/${currentTier.maxUsers}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currentTier == SubscriptionTier.personal
                      ? 'Tu Plan Personal incluye 1 usuario. Para enviar invitaciones por correo, elige abajo el Plan Familiar (4 usuarios) o Familiar Plus (7 usuarios).'
                      : 'Envía una invitación por correo. Si el destinatario la acepta, se agrega a tu familia automáticamente.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _inviteNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Familiar (Ej. Esposa, Hijo, Hermano)',
                    prefixIcon: Icon(Icons.badge_outlined),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _inviteEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico para enviar la invitación',
                    hintText: 'familiar@correo.com',
                    prefixIcon: Icon(Icons.mail_outline),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _sendEmailInvitation,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Enviar Invitación por Correo Electrónico'),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (pendingInvites.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Invitaciones Enviadas por Correo (Pendientes de Aceptar)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...pendingInvites.map((inv) => Card(
                color: Colors.amber.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✉️ ${inv.invitedName} (${inv.invitedEmail})',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Text('Esperando a que haga clic en "Aceptar" en su correo...',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _acceptEmailInvitation(inv),
                        icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                        label: const Text('Simular que acepta el correo'),
                      ),
                    ],
                  ),
                ),
              )),
        ],
        const SizedBox(height: 18),

        const Text('Integrantes Activos en la Cuenta',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...members.map((m) {
          final memberSpent = expenses
              .where((e) => e.memberName == m.name)
              .fold(0.0, (s, e) => s + e.amount);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text(m.name[0])),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${m.email} • Gastos registrados: ${currency.format(memberSpent)}'),
              trailing: m.isOwner
                  ? const Chip(label: Text('Titular'))
                  : IconButton(
                      tooltip: 'Quitar de la familia',
                      icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                      onPressed: () {
                        ref.read(householdMembersProvider.notifier).state =
                            members.where((item) => item.id != m.id).toList();
                      },
                    ),
            ),
          );
        }),

        if (isFamily) ...[
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.balance, color: Colors.teal),
              title: const Text('Cuota Equitativa Familiar (Split)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Gasto total compartido: ${currency.format(totalSharedExpense)} • Promedio por integrante (${members.length}): ${currency.format(totalSharedExpense / members.length)}'),
            ),
          ),
        ],
        const SizedBox(height: 28),

        // PLANES DE SUSCRIPCIÓN EN USD CON MENSUAL Y ANUAL (-33%)
        const Text('Planes de Suscripción (Precios en USD)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Suscripción activa: $activeBillingText',
            style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        SegmentedButton<bool>(
          segments: const [
            ButtonSegment<bool>(
              value: false,
              icon: Icon(Icons.calendar_view_month, size: 18),
              label: Text('Pago Mensual'),
            ),
            ButtonSegment<bool>(
              value: true,
              icon: Icon(Icons.stars, size: 18),
              label: Text('Pago Anual (Ahorra 33%)'),
            ),
          ],
          selected: {isAnnualSelected},
          onSelectionChanged: (s) =>
              ref.read(isAnnualBillingSelectedProvider.notifier).state = s.first,
        ),
        const SizedBox(height: 14),

        ...SubscriptionTier.values.map((tier) {
          final isCurrent = tier == currentTier;
          final displayPrice =
              isAnnualSelected ? tier.annualPrice : tier.monthlyPrice;
          final periodLabel = isAnnualSelected ? '/ año' : '/ mes';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.3),
                width: isCurrent ? 2.2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(tier.title,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  tier.maxUsers == 1
                                      ? '1 Usuario'
                                      : 'Hasta ${tier.maxUsers} Usuarios',
                                  style: const TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (isAnnualSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'AHORRAS \$${tier.annualSavingsUsd.toStringAsFixed(2)} USD',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(tier.subtitle,
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${displayPrice.toStringAsFixed(2)} USD $periodLabel',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (isAnnualSelected)
                            Text(
                              'Equivale a \$${tier.annualMonthlyEquivalent.toStringAsFixed(2)} USD / mes',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Text(
                              'O \$${tier.annualPrice.toStringAsFixed(2)} USD al año (33% dto.)',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: isCurrent
                          ? FilledButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                            )
                          : null,
                      onPressed: () =>
                          _openCheckoutForTier(tier, isAnnualSelected),
                      icon: Icon(
                          isCurrent ? Icons.autorenew : Icons.payment,
                          size: 18),
                      label: Text(
                        isCurrent
                            ? (isAnnualSelected
                                ? 'Cambiar mi ${tier.title} a Ciclo Anual (\$${tier.annualPrice.toStringAsFixed(2)} USD)'
                                : 'Plan Activo Actualmente')
                            : 'Elegir ${tier.title} (${isAnnualSelected ? "\$${tier.annualPrice.toStringAsFixed(2)} USD/año" : "\$${tier.monthlyPrice.toStringAsFixed(2)} USD/mes"})',
                      ),
                    ),
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

class _UpgradeTierPromptSheet extends ConsumerWidget {
  final SubscriptionTier currentTier;
  const _UpgradeTierPromptSheet({required this.currentTier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextTier = currentTier == SubscriptionTier.personal
        ? SubscriptionTier.familiar
        : SubscriptionTier.familiarPlus;
    final isAnnual = ref.watch(isAnnualBillingSelectedProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.group_add, size: 44, color: Colors.teal),
        const SizedBox(height: 12),
        Text(
          'Amplía tu cuenta a ${nextTier.title}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu ${currentTier.title} permite máximo ${currentTier.maxUsers} usuario(s). Pásate al ${nextTier.title} (hasta ${nextTier.maxUsers} integrantes) por \$${nextTier.monthlyPrice.toStringAsFixed(2)} USD/mes o \$${nextTier.annualPrice.toStringAsFixed(2)} USD/año (ahorrando 33%).',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  showAdaptiveSheetOrDialog(
                    context: context,
                    child: _TierCheckoutSheet(
                      targetTier: nextTier,
                      initialIsAnnual: isAnnual,
                    ),
                  );
                },
                child: Text('Ver ${nextTier.title}'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TierCheckoutSheet extends ConsumerStatefulWidget {
  final SubscriptionTier targetTier;
  final bool initialIsAnnual;

  const _TierCheckoutSheet({
    required this.targetTier,
    required this.initialIsAnnual,
  });

  @override
  ConsumerState<_TierCheckoutSheet> createState() => _TierCheckoutSheetState();
}

class _TierCheckoutSheetState extends ConsumerState<_TierCheckoutSheet> {
  String _channel = kIsWeb ? 'PAYPHONE_WEB' : 'REVENUECAT_STORE';
  late bool _isAnnual;

  @override
  void initState() {
    super.initState();
    _isAnnual = widget.initialIsAnnual;
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.targetTier;
    final amountUsd = _isAnnual ? tier.annualPrice : tier.monthlyPrice;
    final sku =
        _isAnnual ? tier.revenueCatAnnualSku : tier.revenueCatMonthlySku;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Suscripción ${tier.title} (${tier.maxUsers} usuarios)',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        SegmentedButton<bool>(
          segments: [
            ButtonSegment<bool>(
              value: false,
              label: Text('Mensual (\$${tier.monthlyPrice.toStringAsFixed(2)} USD)'),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text('Anual (\$${tier.annualPrice.toStringAsFixed(2)} USD • -33%)'),
            ),
          ],
          selected: {_isAnnual},
          onSelectionChanged: (s) => setState(() => _isAnnual = s.first),
        ),
        const SizedBox(height: 12),

        if (_isAnnual)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: Text(
              '★ Descuento Anual Aplicado: Equivale a \$${tier.annualMonthlyEquivalent.toStringAsFixed(2)} USD/mes (Ahorras \$${tier.annualSavingsUsd.toStringAsFixed(2)} USD al año).',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 14),

        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'PAYPHONE_WEB',
              icon: Icon(Icons.language, size: 16),
              label: Text('Payphone Web'),
            ),
            ButtonSegment(
              value: 'REVENUECAT_STORE',
              icon: Icon(Icons.phone_iphone, size: 16),
              label: Text('RevenueCat App'),
            ),
          ],
          selected: {_channel},
          onSelectionChanged: (s) => setState(() => _channel = s.first),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _channel == 'PAYPHONE_WEB'
                ? '• Pasarela: Payphone Cajita de Pagos V2\n• Total a pagar: \$${amountUsd.toStringAsFixed(2)} USD (Impuestos incluidos)\n• Confirmación inmediata en POST /api/button/V2/Confirm'
                : '• Pasarela: RevenueCat (Google Play / App Store)\n• Producto: $sku\n• Total a pagar: \$${amountUsd.toStringAsFixed(2)} USD (${_isAnnual ? "Facturación Anual" : "Facturación Mensual"})',
            style: const TextStyle(fontSize: 12, height: 1.45),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  ref.read(subscriptionTierProvider.notifier).state = tier;
                  ref.read(isAnnualBillingSelectedProvider.notifier).state = _isAnnual;
                  ref.read(activeBillingCycleTextProvider.notifier).state =
                      '${tier.title} (${_isAnnual ? "\$${tier.annualPrice.toStringAsFixed(2)} USD/año" : "\$${tier.monthlyPrice.toStringAsFixed(2)} USD/mes"}) vía ${_channel == "PAYPHONE_WEB" ? "Payphone" : "RevenueCat"}';
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✓ ${tier.title} (${_isAnnual ? "Anual" : "Mensual"}) activado por \$${amountUsd.toStringAsFixed(2)} USD.'),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('Pagar \$${amountUsd.toStringAsFixed(2)} USD'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// MODAL MANUAL (GASTO | INGRESO | RECARGAR BILLETERA / TRANSFERIR)
// ============================================================================
class ManualTxFormModal extends ConsumerStatefulWidget {
  final int initialType;
  const ManualTxFormModal({super.key, this.initialType = 2});
  @override
  ConsumerState<ManualTxFormModal> createState() => _ManualTxFormModalState();
}

class _ManualTxFormModalState extends ConsumerState<ManualTxFormModal> {
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
    final members = ref.watch(householdMembersProvider);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _type == 3 ? 'Recargar Billetera / Transferir' : 'Registro Detallado',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 2, label: Text('Gasto')),
            ButtonSegment(value: 1, label: Text('Ingreso')),
            ButtonSegment(value: 3, label: Text('Transferir')),
          ],
          selected: {_type},
          onSelectionChanged: (v) => setState(() => _type = v.first),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto (USD)',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedAccount,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: _type == 3 ? 'Cuenta Origen' : 'Cuenta o Billetera',
          ),
          items: accounts
              .map((a) => DropdownMenuItem(
                    value: a.name,
                    child: Text('${a.name} (${a.type})', overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedAccount = v),
        ),
        const SizedBox(height: 12),
        if (_type == 3)
          DropdownButtonFormField<String>(
            value: _destinationAccount,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Cuenta o Billetera Destino'),
            items: accounts
                .map((a) => DropdownMenuItem(
                      value: a.name,
                      child: Text('${a.name} (${a.type})', overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _destinationAccount = v),
          )
        else
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: filteredCategories
                .map((c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  final amt = double.tryParse(_amountCtrl.text) ?? 0;
                  if (amt <= 0 || _selectedAccount == null) return;

                  final list = ref.read(transactionsListProvider);
                  if (_type == 3) {
                    if (_destinationAccount == null ||
                        _destinationAccount == _selectedAccount) return;
                    ref.read(transactionsListProvider.notifier).state = [
                      TxItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        description: _descCtrl.text.isEmpty
                            ? 'Recarga / Transferencia'
                            : _descCtrl.text,
                        amount: amt,
                        type: 3,
                        categoryName: 'Transferencia',
                        accountName: '$_selectedAccount → $_destinationAccount',
                        memberName: members.first.name,
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
                        description:
                            _descCtrl.text.isEmpty ? 'Movimiento' : _descCtrl.text,
                        amount: amt,
                        type: _type,
                        categoryName: _selectedCategory!,
                        accountName: _selectedAccount!,
                        memberName: members.first.name,
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
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
