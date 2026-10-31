import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences globalPrefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  globalPrefs = await SharedPreferences.getInstance();
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
// MODELOS DE DATOS CON SERIALIZACIÓN JSON REAL
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

  static SubscriptionTier fromCode(String code) =>
      SubscriptionTier.values.firstWhere((e) => e.code == code,
          orElse: () => SubscriptionTier.personal);
}

class RegisteredUser {
  final String id;
  final String fullName;
  final String email;
  final String password;
  final String role; // 'Usuario' | 'SuperAdmin'

  RegisteredUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  bool get isSuperAdmin => role == 'SuperAdmin';

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
      };

  factory RegisteredUser.fromJson(Map<String, dynamic> j) => RegisteredUser(
        id: j['id'] ?? '',
        fullName: j['fullName'] ?? '',
        email: j['email'] ?? '',
        password: j['password'] ?? '',
        role: j['role'] ?? 'Usuario',
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'isOwner': isOwner,
      };

  factory HouseholdMember.fromJson(Map<String, dynamic> j) => HouseholdMember(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        isOwner: j['isOwner'] ?? false,
      );
}

class EmailInvitation {
  final String id;
  final String invitedName;
  final String invitedEmail;
  final String token;

  EmailInvitation({
    required this.id,
    required this.invitedName,
    required this.invitedEmail,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'invitedName': invitedName,
        'invitedEmail': invitedEmail,
        'token': token,
      };

  factory EmailInvitation.fromJson(Map<String, dynamic> j) => EmailInvitation(
        id: j['id'] ?? '',
        invitedName: j['invitedName'] ?? '',
        invitedEmail: j['invitedEmail'] ?? '',
        token: j['token'] ?? '',
      );
}

class FinancialStoryTip {
  final String id;
  final String tag;
  final String title;
  final String body;
  final String actionTip;
  final int themeIndex;
  final bool isSeen;

  FinancialStoryTip({
    required this.id,
    required this.tag,
    required this.title,
    required this.body,
    required this.actionTip,
    this.themeIndex = 0,
    this.isSeen = false,
  });

  List<Color> get gradientColors {
    const palettes = [
      [Color(0xFF0D6E6E), Color(0xFF064E3B)],
      [Color(0xFF0369A1), Color(0xFF1E3A8A)],
      [Color(0xFFB45309), Color(0xFF78350F)],
      [Color(0xFF6D28D9), Color(0xFF4C1D95)],
    ];
    return palettes[themeIndex.clamp(0, palettes.length - 1)];
  }

  FinancialStoryTip copyWith({bool? isSeen}) => FinancialStoryTip(
        id: id,
        tag: tag,
        title: title,
        body: body,
        actionTip: actionTip,
        themeIndex: themeIndex,
        isSeen: isSeen ?? this.isSeen,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tag': tag,
        'title': title,
        'body': body,
        'actionTip': actionTip,
        'themeIndex': themeIndex,
        'isSeen': isSeen,
      };

  factory FinancialStoryTip.fromJson(Map<String, dynamic> j) => FinancialStoryTip(
        id: j['id'] ?? '',
        tag: j['tag'] ?? 'TIP OFICIAL CASH • 5 SEG',
        title: j['title'] ?? '',
        body: j['body'] ?? '',
        actionTip: j['actionTip'] ?? '',
        themeIndex: j['themeIndex'] ?? 0,
        isSeen: j['isSeen'] ?? false,
      );
}

class AccountModel {
  final String id;
  final String name;
  final String type; // Banco, Billetera Digital, Efectivo, Tarjeta de Crédito, Ahorro, Cooperativa
  final double balance;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  AccountModel copyWith({String? name, String? type, double? balance}) => AccountModel(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'balance': balance,
      };

  factory AccountModel.fromJson(Map<String, dynamic> j) => AccountModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? 'Banco',
        balance: (j['balance'] as num?)?.toDouble() ?? 0.0,
      );
}

class CategoryModel {
  final String id;
  final String name;
  final int type; // 1 = Ingreso, 2 = Gasto
  final double monthlyBudget;
  final String bucket503020;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.monthlyBudget,
    this.bucket503020 = 'Necesidades (50%)',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'monthlyBudget': monthlyBudget,
        'bucket503020': bucket503020,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        type: j['type'] ?? 2,
        monthlyBudget: (j['monthlyBudget'] as num?)?.toDouble() ?? 0.0,
        bucket503020: j['bucket503020'] ?? 'Necesidades (50%)',
      );
}

class TxItem {
  final String id;
  final String description;
  final double amount;
  final int type; // 1 = Ingreso, 2 = Gasto, 3 = Transferencia / Recarga
  final String categoryName;
  final String accountName;
  final String? destinationAccountName;
  final String memberName;
  final DateTime date;

  TxItem({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.categoryName,
    required this.accountName,
    this.destinationAccountName,
    required this.memberName,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'type': type,
        'categoryName': categoryName,
        'accountName': accountName,
        'destinationAccountName': destinationAccountName,
        'memberName': memberName,
        'date': date.toIso8601String(),
      };

  factory TxItem.fromJson(Map<String, dynamic> j) => TxItem(
        id: j['id'] ?? '',
        description: j['description'] ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        type: j['type'] ?? 2,
        categoryName: j['categoryName'] ?? '',
        accountName: j['accountName'] ?? '',
        destinationAccountName: j['destinationAccountName'],
        memberName: j['memberName'] ?? '',
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      );
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
    this.cutOffDay = 15,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardName': cardName,
        'description': description,
        'totalAmount': totalAmount,
        'totalMonths': totalMonths,
        'paidMonths': paidMonths,
        'cutOffDay': cutOffDay,
        'paymentDueDay': paymentDueDay,
      };

  factory CreditInstallmentModel.fromJson(Map<String, dynamic> j) =>
      CreditInstallmentModel(
        id: j['id'] ?? '',
        cardName: j['cardName'] ?? '',
        description: j['description'] ?? '',
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0.0,
        totalMonths: j['totalMonths'] ?? 12,
        paidMonths: j['paidMonths'] ?? 0,
        cutOffDay: j['cutOffDay'] ?? 15,
        paymentDueDay: j['paymentDueDay'] ?? 2,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline,
      };

  factory SavingsGoalModel.fromJson(Map<String, dynamic> j) => SavingsGoalModel(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        targetAmount: (j['targetAmount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (j['currentAmount'] as num?)?.toDouble() ?? 0.0,
        deadline: j['deadline'] ?? '',
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'dueDay': dueDay,
        'isPaid': isPaid,
      };

  factory RecurringBillModel.fromJson(Map<String, dynamic> j) => RecurringBillModel(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        category: j['category'] ?? 'Servicios Básicos',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        dueDay: j['dueDay'] ?? 15,
        isPaid: j['isPaid'] ?? false,
      );
}

// ============================================================================
// MOTOR DE BASE DE DATOS Y PERSISTENCIA REAL POR USUARIO (SHARED PREFERENCES)
// ============================================================================
class CashStorageEngine {
  static const String _usersKey = 'cash_prod_users_v2';
  static const String _lastBioEmailKey = 'cash_prod_last_bio_email_v2';
  static const String _storiesKey = 'cash_prod_global_stories_v2';

  static List<RegisteredUser> getRegisteredUsers() {
    final raw = globalPrefs.getString(_usersKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => RegisteredUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveRegisteredUsers(List<RegisteredUser> users) async {
    await globalPrefs.setString(
        _usersKey, jsonEncode(users.map((e) => e.toJson()).toList()));
  }

  static String? getLastBiometricEmail() => globalPrefs.getString(_lastBioEmailKey);

  static Future<void> setLastBiometricEmail(String email) async {
    await globalPrefs.setString(_lastBioEmailKey, email.toLowerCase().trim());
  }

  static List<FinancialStoryTip> getGlobalStories() {
    final raw = globalPrefs.getString(_storiesKey);
    if (raw == null) {
      return [
        FinancialStoryTip(
          id: 's1',
          tag: 'TIP OFICIAL CASH • 5 SEG',
          title: 'Regla de las 24 Horas',
          body:
              'Antes de realizar un gasto no planificado mayor a \$30 USD, espera 24 horas. El 70% de las compras impulsivas se evitan con esta pausa.',
          actionTip: 'Registra hoy todos tus movimientos reales.',
          themeIndex: 0,
          isSeen: false,
        ),
      ];
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => FinancialStoryTip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveGlobalStories(List<FinancialStoryTip> stories) async {
    await globalPrefs.setString(
        _storiesKey, jsonEncode(stories.map((e) => e.toJson()).toList()));
  }

  static String _userKey(String email, String suffix) =>
      'cash_u_${email.toLowerCase().trim()}_$suffix';

  // Inicializa un espacio de trabajo 100% limpio (Saldos en $0.00, 0 movimientos falsos)
  static Future<void> initializeCleanWorkspaceForNewUser(RegisteredUser user) async {
    final email = user.email;
    if (globalPrefs.getString(_userKey(email, 'accounts')) != null) return;

    final cleanAccounts = [
      AccountModel(id: 'acc_1', name: 'Cuenta Bancaria Principal', type: 'Banco', balance: 0.00),
      AccountModel(id: 'acc_2', name: 'Billetera Digital (Payphone / Deuna)', type: 'Billetera Digital', balance: 0.00),
      AccountModel(id: 'acc_3', name: 'Efectivo Disponible', type: 'Efectivo', balance: 0.00),
    ];

    final defaultCategories = [
      CategoryModel(id: 'cat_1', name: 'Supermercado y Alimentación', type: 2, monthlyBudget: 400.00, bucket503020: 'Necesidades (50%)'),
      CategoryModel(id: 'cat_2', name: 'Servicios Básicos (Luz/Agua/Internet)', type: 2, monthlyBudget: 150.00, bucket503020: 'Necesidades (50%)'),
      CategoryModel(id: 'cat_3', name: 'Educación y Salud', type: 2, monthlyBudget: 200.00, bucket503020: 'Necesidades (50%)'),
      CategoryModel(id: 'cat_4', name: 'Transporte y Combustible', type: 2, monthlyBudget: 120.00, bucket503020: 'Necesidades (50%)'),
      CategoryModel(id: 'cat_5', name: 'Restaurantes, Salidas y Ocio', type: 2, monthlyBudget: 100.00, bucket503020: 'Deseos / Estilo de Vida (30%)'),
      CategoryModel(id: 'cat_6', name: 'Sueldo / Ingreso Principal', type: 1, monthlyBudget: 0.00),
      CategoryModel(id: 'cat_7', name: 'Honorarios / Otros Ingresos', type: 1, monthlyBudget: 0.00),
    ];

    final initialMembers = [
      HouseholdMember(id: user.id, name: user.fullName, email: user.email, isOwner: true),
    ];

    await saveAccounts(email, cleanAccounts);
    await saveCategories(email, defaultCategories);
    await saveTransactions(email, []); // 0 transacciones falsas
    await saveInstallments(email, []); // 0 diferidos falsos
    await saveGoals(email, []);        // 0 metas falsas
    await saveBills(email, []);        // 0 pagos fijos falsos
    await saveMembers(email, initialMembers);
    await saveInvitations(email, []);
    await saveTier(email, SubscriptionTier.personal, false, 'Plan Personal (\$1.99 USD/mes)');
  }

  static List<AccountModel> getAccounts(String email) {
    final raw = globalPrefs.getString(_userKey(email, 'accounts'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => AccountModel.fromJson(e)).toList();
  }

  static Future<void> saveAccounts(String email, List<AccountModel> list) async =>
      globalPrefs.setString(_userKey(email, 'accounts'), jsonEncode(list.map((e) => e.toJson()).toList()));

  static List<CategoryModel> getCategories(String email) {
    final raw = globalPrefs.getString(_userKey(email, 'categories'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => CategoryModel.fromJson(e)).toList();
  }

  static Future<void> saveCategories(String email, List<CategoryModel> list) async =>
      globalPrefs.setString(_userKey(email, 'categories'), jsonEncode(list.map((e) => e.toJson()).toList()));

  static List<TxItem> getTransactions(String email) {
    final raw = globalPrefs.getString(_userKey(email, 'tx'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => TxItem.fromJson(e)).toList();
  }

  static Future<void> saveTransactions(String email, List<TxItem> list) async =>
      globalPrefs.setString(_userKey(email, 'tx'), jsonEncode(list.map((e) => e.toJson()).toList()));

  static List<CreditInstallmentModel> getInstallments(String email) {
    final raw = globalPrefs.getString(_userKey(email, 'installments'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => CreditInstallmentModel.fromJson(e)).toList();
  }

  static Future<void> saveInstallments(String email, List<CreditInstallmentModel> list) async =>
      globalPrefs.setString(_userKey(email, 'installments'), jsonEncode(list.map((e) => e.toJson()).toList()));

  static List<SavingsGoalModel> getGoals(String email) {
    final raw = globalPrefs.getString(_userKey(email, 'goals'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => SavingsGoalModel.fromJson(e)).toList();
  }

  static Future<void> saveGoals(String email, List<SavingsGoalModel> list) async =>
      globalPrefs.setString(_userKey(email, 'goals'), jsonEncode(list.map((e) => e.toJson()).toList()));

  static List<RecurringBillModel> getBills(String email) {
    final raw = globalPrefs.getString(_userKey(email, 'bills'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => RecurringBillModel.fromJson(e)).toList();
  }

  static Future<void> saveBills(String email, List<RecurringBillModel> list) async =>
      globalPrefs.setString(_userKey(email, 'bills'), jsonEncode(list.map((e) => e.toJson()).toList()));

  static List<HouseholdMember> getMembers(String email) {
    final raw = globalPrefs.getString(_userKey(email, 'members'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => HouseholdMember.fromJson(e)).toList();
  }

  static Future<void> saveMembers(String email, List<HouseholdMember> list) async =>
      globalPrefs.setString(_userKey(email, 'members'), jsonEncode(list.map((e) => e.toJson()).toList()));

  static List<EmailInvitation> getInvitations(String email) {
    final raw = globalPrefs.getString(_userKey(email, 'invites'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => EmailInvitation.fromJson(e)).toList();
  }

  static Future<void> saveInvitations(String email, List<EmailInvitation> list) async =>
      globalPrefs.setString(_userKey(email, 'invites'), jsonEncode(list.map((e) => e.toJson()).toList()));

  static (SubscriptionTier, bool, String) getTierInfo(String email) {
    final code = globalPrefs.getString(_userKey(email, 'tier_code')) ?? 'personal';
    final isAnnual = globalPrefs.getBool(_userKey(email, 'tier_annual')) ?? true;
    final label = globalPrefs.getString(_userKey(email, 'tier_label')) ?? 'Plan Personal (\$1.99 USD/mes)';
    return (SubscriptionTier.fromCode(code), isAnnual, label);
  }

  static Future<void> saveTier(String email, SubscriptionTier tier, bool isAnnual, String label) async {
    await globalPrefs.setString(_userKey(email, 'tier_code'), tier.code);
    await globalPrefs.setBool(_userKey(email, 'tier_annual'), isAnnual);
    await globalPrefs.setString(_userKey(email, 'tier_label'), label);
  }
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
  })? parse(String rawText, List<AccountModel> accounts, List<CategoryModel> categories) {
    final text = rawText.trim();
    if (text.isEmpty || accounts.isEmpty) return null;

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
        lower.contains('salario') ||
        lower.contains('honorarios');

    // Buscar si el texto menciona el nombre de alguna cuenta creada por el usuario
    String selectedAccount = accounts.first.name;
    for (final acc in accounts) {
      if (lower.contains(acc.name.toLowerCase())) {
        selectedAccount = acc.name;
        break;
      }
    }
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

    final expenseCats = categories.where((c) => c.type == 2).toList();
    final incomeCats = categories.where((c) => c.type == 1).toList();

    String category = isIncome
        ? (incomeCats.isNotEmpty ? incomeCats.first.name : 'Ingresos')
        : (expenseCats.isNotEmpty ? expenseCats.first.name : 'General');

    if (!isIncome) {
      if (lower.contains('taxi') ||
          lower.contains('uber') ||
          lower.contains('bus') ||
          lower.contains('gasolina')) {
        final matchCat = expenseCats.where((c) => c.name.toLowerCase().contains('transporte')).firstOrNull;
        if (matchCat != null) category = matchCat.name;
      } else if (lower.contains('luz') ||
          lower.contains('agua') ||
          lower.contains('internet') ||
          lower.contains('plan')) {
        final matchCat = expenseCats.where((c) => c.name.toLowerCase().contains('servicio')).firstOrNull;
        if (matchCat != null) category = matchCat.name;
      } else if (lower.contains('farmacia') ||
          lower.contains('medico') ||
          lower.contains('salud') ||
          lower.contains('colegio')) {
        final matchCat = expenseCats.where((c) => c.name.toLowerCase().contains('salud') || c.name.toLowerCase().contains('educa')).firstOrNull;
        if (matchCat != null) category = matchCat.name;
      } else if (lower.contains('cafe') ||
          lower.contains('cine') ||
          lower.contains('salida') ||
          lower.contains('restaurante') ||
          lower.contains('pizza')) {
        final matchCat = expenseCats.where((c) => c.name.toLowerCase().contains('restaurante') || c.name.toLowerCase().contains('ocio')).firstOrNull;
        if (matchCat != null) category = matchCat.name;
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
// PROVIDERS GLOBALES SINCRONIZADOS CON PERSISTENCIA REAL
// ============================================================================
final authSessionProvider = StateProvider<RegisteredUser?>((ref) => null);
final isDarkModeProvider = StateProvider<bool>((ref) => false);
final navIndexProvider = StateProvider<int>((ref) => 0);
final copilotSubTabProvider = StateProvider<int>((ref) => 0);
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final storiesProvider = StateProvider<List<FinancialStoryTip>>(
    (ref) => CashStorageEngine.getGlobalStories());

final accountsProvider = StateProvider<List<AccountModel>>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return [];
  return CashStorageEngine.getAccounts(user.email);
});

final categoriesProvider = StateProvider<List<CategoryModel>>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return [];
  return CashStorageEngine.getCategories(user.email);
});

final transactionsListProvider = StateProvider<List<TxItem>>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return [];
  return CashStorageEngine.getTransactions(user.email);
});

final installmentsProvider = StateProvider<List<CreditInstallmentModel>>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return [];
  return CashStorageEngine.getInstallments(user.email);
});

final savingsGoalsProvider = StateProvider<List<SavingsGoalModel>>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return [];
  return CashStorageEngine.getGoals(user.email);
});

final recurringBillsProvider = StateProvider<List<RecurringBillModel>>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return [];
  return CashStorageEngine.getBills(user.email);
});

final householdMembersProvider = StateProvider<List<HouseholdMember>>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return [];
  return CashStorageEngine.getMembers(user.email);
});

final pendingInvitationsProvider = StateProvider<List<EmailInvitation>>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return [];
  return CashStorageEngine.getInvitations(user.email);
});

final subscriptionTierProvider = StateProvider<SubscriptionTier>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return SubscriptionTier.personal;
  return CashStorageEngine.getTierInfo(user.email).$1;
});

final isAnnualBillingSelectedProvider = StateProvider<bool>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return true;
  return CashStorageEngine.getTierInfo(user.email).$2;
});

final activeBillingCycleTextProvider = StateProvider<String>((ref) {
  final user = ref.watch(authSessionProvider);
  if (user == null) return 'Plan Personal (\$1.99 USD/mes)';
  return CashStorageEngine.getTierInfo(user.email).$3;
});

// REGLA AUTOMÁTICA: 1 persona = Modo Personal (false) | >1 personas = Modo Familiar (true)
final isFamilyModeProvider = Provider<bool>((ref) {
  final members = ref.watch(householdMembersProvider);
  return members.length > 1;
});

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
      final updated = stories
          .map((s) => s.id == targetId ? s.copyWith(isSeen: true) : s)
          .toList();
      ref.read(storiesProvider.notifier).state = updated;
      CashStorageEngine.saveGlobalStories(updated);
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
                                  label: const Text('+ Publicar Tip',
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

  final _themeNames = const [
    'Verde Salvia (Armonía Familiar)',
    'Azul Océano (Control Personal)',
    'Ámbar Dorado (Ahorro Inteligente)',
    'Violeta Profundo (Inversión)',
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
                'Publicar Nueva Historia Diaria (5s)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Título del Tip',
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
            labelText: 'Reto o acción sugerida',
            prefixIcon: Icon(Icons.bolt),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _selectedTheme,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Color de Fondo'),
          items: List.generate(
            _themeNames.length,
            (i) => DropdownMenuItem(value: i, child: Text(_themeNames[i])),
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
                  final updated = [
                    ...current,
                    FinancialStoryTip(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      tag: 'TIP OFICIAL CASH • 5 SEG',
                      title: _titleCtrl.text.trim(),
                      body: _bodyCtrl.text.trim(),
                      actionTip: _actionCtrl.text.trim(),
                      themeIndex: _selectedTheme,
                      isSeen: false,
                    ),
                  ];
                  ref.read(storiesProvider.notifier).state = updated;
                  CashStorageEngine.saveGlobalStories(updated);
                  Navigator.pop(context);
                  widget.onCreated();
                },
                icon: const Icon(Icons.publish, size: 18),
                label: const Text('Publicar Historia'),
              ),
            ),
          ],
        ),
      ],
    );
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
    final isFamily = ref.watch(isFamilyModeProvider);

    final seedColor = isFamily ? const Color(0xFF0D6E6E) : const Color(0xFF0369A1);
    final lightBg = isFamily ? const Color(0xFFF3F7F5) : const Color(0xFFF1F5F9);

    return MaterialApp(
      title: 'Cash · Control de Gastos Personal y Familiar',
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
      home: session == null ? const RealAuthScreen() : const CompleteHomeShell(),
    );
  }
}

// ============================================================================
// PANTALLA DE REGISTRO E INICIO DE SESIÓN REAL (CERO BOTONES DEMO)
// ============================================================================
class RealAuthScreen extends ConsumerStatefulWidget {
  const RealAuthScreen({super.key});
  @override
  ConsumerState<RealAuthScreen> createState() => _RealAuthScreenState();
}

class _RealAuthScreenState extends ConsumerState<RealAuthScreen> {
  bool _isRegisterMode = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _registerAsAppAdmin = false;
  bool _scanningFingerprint = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final users = CashStorageEngine.getRegisteredUsers();
    if (users.isEmpty) {
      // Si aún no hay ningún usuario creado en el dispositivo, abre directo en "Crear Cuenta"
      _isRegisterMode = true;
    } else {
      final lastEmail = CashStorageEngine.getLastBiometricEmail();
      if (lastEmail != null) {
        _emailCtrl.text = lastEmail;
      }
    }
  }

  Future<void> _submitAuth() async {
    setState(() => _errorMsg = null);
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass = _passCtrl.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Ingresa un correo electrónico válido.');
      return;
    }
    if (pass.length < 4) {
      setState(() => _errorMsg = 'La contraseña debe tener al menos 4 caracteres.');
      return;
    }

    final users = CashStorageEngine.getRegisteredUsers();

    if (_isRegisterMode) {
      final fullName = _nameCtrl.text.trim();
      if (fullName.isEmpty) {
        setState(() => _errorMsg = 'Ingresa tu nombre completo.');
        return;
      }
      if (pass != _confirmPassCtrl.text) {
        setState(() => _errorMsg = 'Las contraseñas no coinciden.');
        return;
      }
      if (users.any((u) => u.email.toLowerCase() == email)) {
        setState(() =>
            _errorMsg = 'Este correo ya está registrado. Cambia a "Iniciar Sesión".');
        return;
      }

      final newUser = RegisteredUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: fullName,
        email: email,
        password: pass,
        role: _registerAsAppAdmin ? 'SuperAdmin' : 'Usuario',
      );

      final updatedUsers = [...users, newUser];
      await CashStorageEngine.saveRegisteredUsers(updatedUsers);
      await CashStorageEngine.initializeCleanWorkspaceForNewUser(newUser);
      await CashStorageEngine.setLastBiometricEmail(newUser.email);

      ref.read(authSessionProvider.notifier).state = newUser;
    } else {
      final match = users
          .where((u) => u.email.toLowerCase() == email && u.password == pass)
          .firstOrNull;
      if (match == null) {
        setState(() =>
            _errorMsg = 'Correo o contraseña incorrectos. Si eres nuevo, pulsa "Crear Cuenta".');
        return;
      }
      await CashStorageEngine.initializeCleanWorkspaceForNewUser(match);
      await CashStorageEngine.setLastBiometricEmail(match.email);
      ref.read(authSessionProvider.notifier).state = match;
    }
  }

  Future<void> _loginWithBiometricFingerprint() async {
    final lastEmail = CashStorageEngine.getLastBiometricEmail();
    final users = CashStorageEngine.getRegisteredUsers();
    final targetUser = lastEmail != null
        ? users.where((u) => u.email.toLowerCase() == lastEmail).firstOrNull
        : users.firstOrNull;

    if (targetUser == null) {
      setState(() {
        _isRegisterMode = true;
        _errorMsg = 'Primero registra tu cuenta para vincular tu Huella Digital en este dispositivo.';
      });
      return;
    }

    setState(() {
      _scanningFingerprint = true;
      _errorMsg = null;
    });
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _scanningFingerprint = false);

    await CashStorageEngine.initializeCleanWorkspaceForNewUser(targetUser);
    ref.read(authSessionProvider.notifier).state = targetUser;
  }

  @override
  Widget build(BuildContext context) {
    final registeredUsers = CashStorageEngine.getRegisteredUsers();
    final lastBioEmail = CashStorageEngine.getLastBiometricEmail();
    final bioUser = lastBioEmail != null
        ? registeredUsers.where((u) => u.email.toLowerCase() == lastBioEmail).firstOrNull
        : registeredUsers.firstOrNull;

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
                  const SizedBox(height: 12),
                  const Text('Cash',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const Text(
                    'Control financiero personal y familiar',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Selector: Iniciar Sesión vs Crear Cuenta Nueva
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.login, size: 18),
                        label: Text('Iniciar Sesión'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.person_add_alt_1, size: 18),
                        label: Text('Crear Cuenta'),
                      ),
                    ],
                    selected: {_isRegisterMode},
                    onSelectionChanged: (s) => setState(() {
                      _isRegisterMode = s.first;
                      _errorMsg = null;
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Tarjeta de Huella Digital (Solo aparece si ya hay una cuenta registrada en el dispositivo)
                  if (!_isRegisterMode && bioUser != null) ...[
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _scanningFingerprint
                            ? null
                            : _loginWithBiometricFingerprint,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.fingerprint,
                                    size: 30, color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _scanningFingerprint
                                          ? 'Verificando huella...'
                                          : 'Entrar con Huella Digital',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      'Cuenta vinculada: ${bioUser.fullName} (${bioUser.email})',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Formulario Real de Registro o Login
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isRegisterMode
                                ? 'Crear mi Cuenta desde Cero'
                                : 'Ingresa con tus Credenciales',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),
                          if (_isRegisterMode) ...[
                            TextField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Tu Nombre Completo',
                                hintText: 'Ej. Alex Ejemplo',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo Electrónico',
                              hintText: 'tu@correo.com',
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
                          if (_isRegisterMode) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPassCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirmar Contraseña',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                            ),
                            const SizedBox(height: 10),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text(
                                'Soy el Administrador / Desarrollador de Cash',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                'Habilita la consola para publicar historias diarias de 5s',
                                style: TextStyle(fontSize: 11),
                              ),
                              value: _registerAsAppAdmin,
                              onChanged: (v) => setState(
                                  () => _registerAsAppAdmin = v ?? false),
                            ),
                          ],
                          if (_errorMsg != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _errorMsg!,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _submitAuth,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: Icon(_isRegisterMode
                                ? Icons.check_circle_outline
                                : Icons.login),
                            label: Text(_isRegisterMode
                                ? 'Registrarme y Empezar en \$0.00'
                                : 'Iniciar Sesión'),
                          ),
                        ],
                      ),
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
// SHELL PRINCIPAL DE 4 PESTAÑAS CON PERSISTENCIA REAL
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
                    '✓ Historia publicada y guardada permanentemente.')),
          );
        },
      ),
    );
  }

  void _openInvoiceScanner(BuildContext context) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: const RealInvoiceScannerModal(),
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
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: unseenCount > 0
                                      ? const Color(0xFFF43F5E).withOpacity(0.14)
                                      : Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
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
                                        : Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isFamily
                              ? '${session?.fullName} • Modo Familiar (${members.length} miembros)'
                              : '${session?.fullName} • Modo Personal',
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Lector Real de Facturas XML (SRI) / OCR',
                icon: const Icon(Icons.document_scanner_outlined),
                onPressed: () => _openInvoiceScanner(context),
              ),
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
                    label: const Text('+ Tip 5s', style: TextStyle(fontSize: 11)),
                  ),
                ),
              IconButton(
                tooltip: isDark ? 'Modo Claro' : 'Modo Oscuro',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () =>
                    ref.read(isDarkModeProvider.notifier).state = !isDark,
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    ref.read(authSessionProvider.notifier).state = null,
              ),
            ],
          ),
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  extended: constraints.maxWidth >= 1150,
                  selectedIndex: navIdx,
                  onDestinationSelected: (i) =>
                      ref.read(navIndexProvider.notifier).state = i,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.wb_sunny_outlined),
                      selectedIcon: Icon(Icons.wb_sunny),
                      label: Text('Hoy & Facturas XML'),
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
                  onDestinationSelected: (i) =>
                      ref.read(navIndexProvider.notifier).state = i,
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.wb_sunny_outlined), label: 'Hoy'),
                    NavigationDestination(
                        icon: Icon(Icons.account_balance_wallet_outlined),
                        label: 'Billeteras'),
                    NavigationDestination(
                        icon: Icon(Icons.insights_outlined), label: 'Copiloto'),
                    NavigationDestination(
                        icon: Icon(Icons.group_add_outlined),
                        label: 'Familia & Plan'),
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
// LECTOR REAL DE FACTURAS ELECTRÓNICAS XML (SRI ECUADOR) Y FACTURA MANUAL
// ============================================================================
class RealInvoiceScannerModal extends ConsumerStatefulWidget {
  const RealInvoiceScannerModal({super.key});
  @override
  ConsumerState<RealInvoiceScannerModal> createState() =>
      _RealInvoiceScannerModalState();
}

class _RealInvoiceScannerModalState
    extends ConsumerState<RealInvoiceScannerModal> {
  final _xmlPasteCtrl = TextEditingController();
  final _merchantCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  String? _selectedAccount;
  String? _selectedCategory;

  void _parseSriXml(String xmlContent) {
    final razonMatch =
        RegExp(r'<razonSocial>(.*?)</razonSocial>', caseSensitive: false)
            .firstMatch(xmlContent);
    final importeMatch =
        RegExp(r'<importeTotal>(.*?)</importeTotal>', caseSensitive: false)
            .firstMatch(xmlContent);

    setState(() {
      if (razonMatch != null) {
        _merchantCtrl.text = razonMatch.group(1)!.trim();
      }
      if (importeMatch != null) {
        _totalCtrl.text = importeMatch.group(1)!.trim();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider);
    final accounts = ref.watch(accountsProvider);
    final categories =
        ref.watch(categoriesProvider).where((c) => c.type == 2).toList();
    final members = ref.watch(householdMembersProvider);

    final total = double.tryParse(_totalCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final subTotal = total / 1.15;
    final iva15 = total - subTotal;

    if (_selectedAccount == null ||
        !accounts.any((a) => a.name == _selectedAccount)) {
      _selectedAccount = accounts.isNotEmpty ? accounts.first.name : null;
    }
    if (_selectedCategory == null ||
        !categories.any((c) => c.name == _selectedCategory)) {
      _selectedCategory = categories.isNotEmpty ? categories.first.name : null;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.teal),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lector Real de Facturas (XML SRI / Manual)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                      'Pega el XML de tu factura electrónica o ingresa el comercio y total',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 22),
        TextField(
          controller: _xmlPasteCtrl,
          maxLines: 2,
          onChanged: _parseSriXml,
          decoration: const InputDecoration(
            labelText: 'Opcional: Pega aquí el contenido XML de la factura SRI',
            hintText: '<factura>...<razonSocial>Comercio</razonSocial><importeTotal>45.00</importeTotal>...',
            prefixIcon: Icon(Icons.code),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _merchantCtrl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Comercio / Emisor de la Factura',
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
        if (accounts.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _selectedAccount,
            isExpanded: true,
            decoration:
                const InputDecoration(labelText: 'Cuenta o Billetera de Pago'),
            items: accounts
                .map((a) => DropdownMenuItem(
                      value: a.name,
                      child: Text('${a.name} (${a.type})',
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedAccount = v),
          ),
        const SizedBox(height: 12),
        if (categories.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Rubro de Gasto / Deducible'),
            items: categories
                .map((c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Desglose IVA (15%): Subtotal \$${subTotal.toStringAsFixed(2)} USD  +  IVA \$${iva15.toStringAsFixed(2)} USD',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                onPressed: () async {
                  if (total <= 0 ||
                      _selectedAccount == null ||
                      _selectedCategory == null ||
                      user == null) return;

                  final merchant = _merchantCtrl.text.trim().isEmpty
                      ? 'Factura Electrónica'
                      : _merchantCtrl.text.trim();

                  final newTx = TxItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    description:
                        '$merchant (IVA: \$${iva15.toStringAsFixed(2)})',
                    amount: total,
                    type: 2,
                    categoryName: _selectedCategory!,
                    accountName: _selectedAccount!,
                    memberName: members.isNotEmpty
                        ? members.first.name
                        : user.fullName,
                  );

                  final updatedTx = [
                    newTx,
                    ...ref.read(transactionsListProvider)
                  ];
                  ref.read(transactionsListProvider.notifier).state = updatedTx;
                  await CashStorageEngine.saveTransactions(
                      user.email, updatedTx);

                  final updatedAcc = accounts.map((acc) {
                    if (acc.name == _selectedAccount) {
                      return acc.copyWith(balance: acc.balance - total);
                    }
                    return acc;
                  }).toList();
                  ref.read(accountsProvider.notifier).state = updatedAcc;
                  await CashStorageEngine.saveAccounts(user.email, updatedAcc);

                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Guardar Factura Real'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// PESTAÑA 1: "HOY" (DATOS REALES DEL USUARIO + OPCIÓN DE BORRAR MOVIMIENTOS)
// ============================================================================
class TodayDashboardView extends ConsumerStatefulWidget {
  const TodayDashboardView({super.key});
  @override
  ConsumerState<TodayDashboardView> createState() => _TodayDashboardViewState();
}

class _TodayDashboardViewState extends ConsumerState<TodayDashboardView> {
  final _magicInputCtrl = TextEditingController();
  String? _selectedAuthor;

  Future<void> _executeMagicInput(String rawInput) async {
    final user = ref.read(authSessionProvider);
    if (user == null) return;
    final accounts = ref.read(accountsProvider);
    final categories = ref.read(categoriesProvider);
    final members = ref.read(householdMembersProvider);
    final parsed = SmartInputParser.parse(rawInput, accounts, categories);

    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Escribe concepto y monto. Ejemplo: "Almuerzo 8.50 deuna" o "Sueldo 1200"'),
        ),
      );
      return;
    }

    final author = _selectedAuthor ??
        (members.isNotEmpty ? members.first.name : user.fullName);
    final txList = ref.read(transactionsListProvider);
    final updatedTx = [
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
    ref.read(transactionsListProvider.notifier).state = updatedTx;
    await CashStorageEngine.saveTransactions(user.email, updatedTx);

    final updatedAcc = accounts.map((acc) {
      if (acc.name == parsed.accountName) {
        final delta = parsed.type == 1 ? parsed.amount : -parsed.amount;
        return acc.copyWith(balance: acc.balance + delta);
      }
      return acc;
    }).toList();
    ref.read(accountsProvider.notifier).state = updatedAcc;
    await CashStorageEngine.saveAccounts(user.email, updatedAcc);

    _magicInputCtrl.clear();
  }

  Future<void> _deleteTransactionAndRevertBalance(TxItem tx) async {
    final user = ref.read(authSessionProvider);
    if (user == null) return;

    final updatedTx = ref
        .read(transactionsListProvider)
        .where((item) => item.id != tx.id)
        .toList();
    ref.read(transactionsListProvider.notifier).state = updatedTx;
    await CashStorageEngine.saveTransactions(user.email, updatedTx);

    final accounts = ref.read(accountsProvider);
    final updatedAcc = accounts.map((acc) {
      if (tx.type == 3) {
        if (acc.name == tx.accountName) {
          return acc.copyWith(balance: acc.balance + tx.amount);
        }
        if (acc.name == tx.destinationAccountName) {
          return acc.copyWith(balance: acc.balance - tx.amount);
        }
      } else if (acc.name == tx.accountName) {
        final revertDelta = tx.type == 1 ? -tx.amount : tx.amount;
        return acc.copyWith(balance: acc.balance + revertDelta);
      }
      return acc;
    }).toList();
    ref.read(accountsProvider.notifier).state = updatedAcc;
    await CashStorageEngine.saveAccounts(user.email, updatedAcc);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Movimiento eliminado y saldo actualizado.')),
      );
    }
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

    if (members.isNotEmpty &&
        (_selectedAuthor == null ||
            !members.any((m) => m.name == _selectedAuthor))) {
      _selectedAuthor = members.first.name;
    }

    final totalBalance = accounts.fold(0.0, (s, a) => s + a.balance);
    final bankBalance = accounts
        .where((a) =>
            a.type == 'Banco' || a.type == 'Ahorro' || a.type == 'Cooperativa')
        .fold(0.0, (s, a) => s + a.balance);
    final digitalWalletBalance = accounts
        .where((a) => a.type == 'Billetera Digital')
        .fold(0.0, (s, a) => s + a.balance);
    final cashBalance =
        accounts.where((a) => a.type == 'Efectivo').fold(0.0, (s, a) => s + a.balance);

    final income =
        allTx.where((t) => t.type == 1).fold(0.0, (s, t) => s + t.amount);
    final expense =
        allTx.where((t) => t.type == 2).fold(0.0, (s, t) => s + t.amount);
    final savingsRate =
        income > 0 ? ((income - expense) / income * 100).clamp(0.0, 100.0) : 0.0;

    final pendingBills =
        bills.where((b) => !b.isPaid).fold(0.0, (s, b) => s + b.amount);
    final freeMonthMoney =
        (totalBalance - pendingBills).clamp(0.0, double.infinity);

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final remainingDays = (daysInMonth - now.day + 1).clamp(1, 31);
    final safeToSpendToday = freeMonthMoney / remainingDays;

    final txAuthors =
        allTx.where((t) => t.type == 2).map((t) => t.memberName).toSet().toList();
    final filteredTx = allTx.where((t) {
      final matchesMember =
          selectedMember == null || t.memberName == selectedMember;
      final matchesSearch = searchQuery.isEmpty ||
          t.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.categoryName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          t.accountName.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesMember && matchesSearch;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      children: [
        // 1. TARJETA PRINCIPAL DE DISPONIBLE DIARIO Y SALDOS REALES
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                              ? 'Disponible para gastar hoy en familia ($remainingDays días restantes):'
                              : 'Disponible para gastar hoy ($remainingDays días restantes):',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(safeToSpendToday),
                          style: const TextStyle(
                              fontSize: 36, fontWeight: FontWeight.bold),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('Patrimonio Total',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(currency.format(totalBalance),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal)),
                          Text('Tasa Ahorro: ${savingsRate.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 22),
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

        // 2. BARRA DE REGISTRO RÁPIDO EN 3 SEGUNDOS
        Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        Icon(Icons.bolt, color: Colors.teal, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Registro Rápido en 1 Línea',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFamily && members.isNotEmpty)
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
                            onChanged: (v) =>
                                setState(() => _selectedAuthor = v),
                          ),
                        const SizedBox(width: 6),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact),
                          onPressed: () => showAdaptiveSheetOrDialog(
                            context: context,
                            child: const RealInvoiceScannerModal(),
                          ),
                          icon: const Icon(Icons.receipt_long, size: 16),
                          label: const Text('Factura XML',
                              style: TextStyle(fontSize: 12)),
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
                          hintText:
                              'Escribe ej: "Sueldo 1500" o "Almuerzo 6.50 deuna"',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          _executeMagicInput(_magicInputCtrl.text),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      child: const Icon(Icons.send, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 3. HISTORIAL DE MOVIMIENTOS REALES DEL USUARIO
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mis Movimientos Reales',
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
                onSelected: (_) => ref
                    .read(selectedMemberFilterProvider.notifier)
                    .state = null,
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
        if (allTx.isNotEmpty) ...[
          TextField(
            onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
            decoration: const InputDecoration(
              hintText: 'Buscar por descripción, categoría o cuenta...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (filteredTx.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Tu cuenta está limpia y lista para usar',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                    'Registra tu saldo inicial en la pestaña "Billeteras" o anota tu primer ingreso/gasto con el botón "+ Registrar".',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
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
                isTransfer
                    ? '${t.accountName} → ${t.destinationAccountName ?? ""} • ${DateFormat("dd/MM HH:mm").format(t.date)}'
                    : '${t.categoryName} • ${t.accountName} • ${t.memberName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${isTransfer ? '⇄ ' : (isInc ? '+' : '-')}${currency.format(t.amount)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: fgColor),
                  ),
                  IconButton(
                    tooltip: 'Eliminar movimiento y revertir saldo',
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.grey),
                    onPressed: () => _deleteTransactionAndRevertBalance(t),
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
                      fontSize: 11,
                      color:
                          highlight ? Colors.teal.shade100 : Colors.grey)),
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
// PESTAÑA 2: BILLETERAS, CUENTAS (EDITAR/CREAR/BORRAR), PAGOS FIJOS Y RUBROS
// ============================================================================
class WalletsAndCatalogsView extends ConsumerWidget {
  const WalletsAndCatalogsView({super.key});

  void _openAccountForm(BuildContext context,
      {String defaultType = 'Billetera Digital', AccountModel? existing}) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: _AccountCrudForm(defaultType: defaultType, existing: existing),
    );
  }

  void _openAddCategoryModal(BuildContext context, {int defaultType = 2}) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: _AddCategoryForm(defaultType: defaultType),
    );
  }

  void _openAddRecurringBillModal(BuildContext context) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: const _AddRecurringBillForm(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider);
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
        // 1. CUENTAS BANCARIAS Y BILLETERAS DIGITALES (CREAR, EDITAR SALDO Y BORRAR)
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
                  onPressed: () => _openAccountForm(context,
                      defaultType: 'Billetera Digital'),
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('+ Billetera Digital'),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      _openAccountForm(context, defaultType: 'Banco'),
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
              title: Text(a.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text('Tipo: ${a.type} • Saldo: ${currency.format(a.balance)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar nombre o saldo de la cuenta',
                    icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                    onPressed: () => _openAccountForm(context,
                        defaultType: a.type, existing: a),
                  ),
                  IconButton(
                    tooltip: 'Eliminar cuenta',
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: accounts.length <= 1 || user == null
                        ? null
                        : () async {
                            final updated = accounts
                                .where((item) => item.id != a.id)
                                .toList();
                            ref.read(accountsProvider.notifier).state = updated;
                            await CashStorageEngine.saveAccounts(
                                user.email, updated);
                          },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 22),

        // 2. PAGOS FIJOS DEL MES (CREAR, MARCAR PAGADO Y BORRAR)
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('2. Pagos Fijos y Suscripciones del Mes',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            FilledButton.tonalIcon(
              onPressed: () => _openAddRecurringBillModal(context),
              icon: const Icon(Icons.add_alarm, size: 18),
              label: const Text('+ Nuevo Pago Fijo'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (bills.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No tienes pagos fijos configurados. Agrega internet, luz, arriendo o colegiaturas con "+ Nuevo Pago Fijo".',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ...bills.map((b) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(b.isPaid ? Icons.check_circle : Icons.schedule,
                    color: b.isPaid ? Colors.green : Colors.amber.shade800),
                title: Text(b.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    'Vence el día ${b.dueDay} • ${currency.format(b.amount)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (b.isPaid)
                      const Chip(label: Text('Pagado'))
                    else
                      FilledButton.tonal(
                        onPressed: () async {
                          if (user == null) return;
                          final updated = bills
                              .map((item) => item.id == b.id
                                  ? item.copyWith(isPaid: true)
                                  : item)
                              .toList();
                          ref.read(recurringBillsProvider.notifier).state =
                              updated;
                          await CashStorageEngine.saveBills(
                              user.email, updated);
                        },
                        child: const Text('Pagar'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      onPressed: () async {
                        if (user == null) return;
                        final updated =
                            bills.where((item) => item.id != b.id).toList();
                        ref.read(recurringBillsProvider.notifier).state =
                            updated;
                        await CashStorageEngine.saveBills(user.email, updated);
                      },
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 22),

        // 3. RUBROS DE GASTO
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
          final progress = c.monthlyBudget > 0
              ? (spent / c.monthlyBudget).clamp(0.0, 1.0)
              : 0.0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(c.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold))),
                  Text(
                      '${currency.format(spent)} / ${currency.format(c.monthlyBudget)}',
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
                onPressed: expenseCats.length <= 1 || user == null
                    ? null
                    : () async {
                        final updated = categories
                            .where((item) => item.id != c.id)
                            .toList();
                        ref.read(categoriesProvider.notifier).state = updated;
                        await CashStorageEngine.saveCategories(
                            user.email, updated);
                      },
              ),
            ),
          );
        }),
        const SizedBox(height: 22),

        // 4. RUBROS DE INGRESO
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
                  child: Icon(Icons.trending_up,
                      color: Colors.green.shade800, size: 18),
                ),
                title: Text(c.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: incomeCats.length <= 1 || user == null
                      ? null
                      : () async {
                          final updated = categories
                              .where((item) => item.id != c.id)
                              .toList();
                          ref.read(categoriesProvider.notifier).state = updated;
                          await CashStorageEngine.saveCategories(
                              user.email, updated);
                        },
                ),
              ),
            )),
      ],
    );
  }
}

class _AccountCrudForm extends ConsumerStatefulWidget {
  final String defaultType;
  final AccountModel? existing;

  const _AccountCrudForm({required this.defaultType, this.existing});

  @override
  ConsumerState<_AccountCrudForm> createState() => _AccountCrudFormState();
}

class _AccountCrudFormState extends ConsumerState<_AccountCrudForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _balanceCtrl;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.existing?.type ?? widget.defaultType;
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _balanceCtrl = TextEditingController(
        text: widget.existing != null
            ? widget.existing!.balance.toStringAsFixed(2)
            : '0.00');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider);
    final isDigital = _selectedType == 'Billetera Digital';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.existing != null
              ? 'Editar Cuenta / Billetera'
              : 'Nueva Cuenta o Billetera Digital',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
            labelText: isDigital
                ? 'Nombre de la Billetera Digital'
                : 'Nombre de la Cuenta',
            hintText: isDigital
                ? 'Ej. Payphone, Deuna, Peigo...'
                : 'Ej. Banco Pichincha, Produbanco...',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _balanceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Saldo Disponible Actual (USD)',
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
                onPressed: () async {
                  if (_nameCtrl.text.trim().isEmpty || user == null) return;
                  final bal = double.tryParse(
                          _balanceCtrl.text.replaceAll(',', '.')) ??
                      0.0;
                  final current = ref.read(accountsProvider);
                  List<AccountModel> updated;

                  if (widget.existing != null) {
                    updated = current
                        .map((a) => a.id == widget.existing!.id
                            ? a.copyWith(
                                name: _nameCtrl.text.trim(),
                                type: _selectedType,
                                balance: bal)
                            : a)
                        .toList();
                  } else {
                    updated = [
                      ...current,
                      AccountModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _nameCtrl.text.trim(),
                        type: _selectedType,
                        balance: bal,
                      ),
                    ];
                  }

                  ref.read(accountsProvider.notifier).state = updated;
                  await CashStorageEngine.saveAccounts(user.email, updated);
                  if (context.mounted) Navigator.pop(context);
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

class _AddRecurringBillForm extends ConsumerStatefulWidget {
  const _AddRecurringBillForm();
  @override
  ConsumerState<_AddRecurringBillForm> createState() =>
      _AddRecurringBillFormState();
}

class _AddRecurringBillFormState extends ConsumerState<_AddRecurringBillForm> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dueDayCtrl = TextEditingController(text: '10');

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Nuevo Pago Fijo o Suscripción Mensual',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Concepto (Ej. Internet, Luz, Arriendo, Colegio)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto Mensual (USD)',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dueDayCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Día de vencimiento del mes (1 al 31)',
            prefixIcon: Icon(Icons.calendar_today),
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
                onPressed: () async {
                  final amt =
                      double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ??
                          0.0;
                  final day = (int.tryParse(_dueDayCtrl.text) ?? 10).clamp(1, 31);
                  if (_titleCtrl.text.trim().isEmpty ||
                      amt <= 0 ||
                      user == null) return;

                  final updated = [
                    ...ref.read(recurringBillsProvider),
                    RecurringBillModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleCtrl.text.trim(),
                      category: 'Servicios Básicos',
                      amount: amt,
                      dueDay: day,
                    ),
                  ];
                  ref.read(recurringBillsProvider.notifier).state = updated;
                  await CashStorageEngine.saveBills(user.email, updated);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar Pago Fijo'),
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
    _budgetCtrl =
        TextEditingController(text: widget.defaultType == 2 ? '200' : '0');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Parametrizar Rubro de Ingreso / Gasto',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
                value: 2, label: Text('Gasto'), icon: Icon(Icons.trending_down)),
            ButtonSegment(
                value: 1, label: Text('Ingreso'), icon: Icon(Icons.trending_up)),
          ],
          selected: {_selectedType},
          onSelectionChanged: (s) => setState(() => _selectedType = s.first),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: _selectedType == 2
                ? 'Nombre del Rubro de Gasto'
                : 'Nombre del Rubro de Ingreso',
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
            decoration:
                const InputDecoration(labelText: 'Clasificación Regla 50/30/20'),
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
                onPressed: () async {
                  if (_nameCtrl.text.trim().isEmpty || user == null) return;
                  final budget = _selectedType == 2
                      ? (double.tryParse(_budgetCtrl.text) ?? 0.0)
                      : 0.0;
                  final updated = [
                    ...ref.read(categoriesProvider),
                    CategoryModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameCtrl.text.trim(),
                      type: _selectedType,
                      monthlyBudget: budget,
                      bucket503020: _selectedBucket,
                    ),
                  ];
                  ref.read(categoriesProvider.notifier).state = updated;
                  await CashStorageEngine.saveCategories(user.email, updated);
                  if (context.mounted) Navigator.pop(context);
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
// PESTAÑA 3: DIFERIDOS DE TARJETAS, METAS DE AHORRO Y COPILOTO 50/30/20 (CRUD REAL)
// ============================================================================
class CopilotCardsAndGoalsView extends ConsumerWidget {
  const CopilotCardsAndGoalsView({super.key});

  String _generateCsv(List<TxItem> items) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Fecha,Tipo,Categoria,Descripcion,Cuenta_Billetera,Miembro,Monto_USD');
    for (final t in items) {
      final tipo =
          t.type == 1 ? 'INGRESO' : (t.type == 3 ? 'TRANSFERENCIA' : 'GASTO');
      final fecha = DateFormat('yyyy-MM-dd').format(t.date);
      buffer.writeln(
          '$fecha,$tipo,${t.categoryName},${t.description},${t.accountName},${t.memberName},${t.amount.toStringAsFixed(2)}');
    }
    return buffer.toString();
  }

  void _openAddInstallmentModal(BuildContext context) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: const _AddInstallmentForm(),
    );
  }

  void _openAddGoalModal(BuildContext context) {
    showAdaptiveSheetOrDialog(
      context: context,
      child: const _AddGoalForm(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider);
    final subTab = ref.watch(copilotSubTabProvider);
    final installments = ref.watch(installmentsProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final allTx = ref.watch(transactionsListProvider);
    final categories = ref.watch(categoriesProvider);
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final income =
        allTx.where((t) => t.type == 1).fold(0.0, (s, t) => s + t.amount);
    final expenses = allTx.where((t) => t.type == 2).toList();
    final totalExpense = expenses.fold(0.0, (s, e) => s + e.amount);

    double needsSpent = 0;
    double wantsSpent = 0;
    for (final e in expenses) {
      final cat =
          categories.where((c) => c.name == e.categoryName).firstOrNull;
      if (cat != null && cat.bucket503020.contains('30%')) {
        wantsSpent += e.amount;
      } else {
        needsSpent += e.amount;
      }
    }
    final savingsActual =
        (income - totalExpense).clamp(0.0, double.infinity);

    final microExpenses = expenses.where((e) => e.amount <= 15.0).toList();
    final microTotal = microExpenses.fold(0.0, (s, e) => s + e.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
      children: [
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
          onSelectionChanged: (s) =>
              ref.read(copilotSubTabProvider.notifier).state = s.first,
        ),
        const SizedBox(height: 18),

        // SUB-VISTA 0: TARJETAS DE CRÉDITO Y DIFERIDOS REALES
        if (subTab == 0) ...[
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Mis Compras Diferidas y Tarjetas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              FilledButton.icon(
                onPressed: () => _openAddInstallmentModal(context),
                icon: const Icon(Icons.add_card, size: 18),
                label: const Text('+ Nuevo Diferido'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (installments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Aún no has registrado compras diferidas. Usa el botón "+ Nuevo Diferido" para llevar el control de tus cuotas y fechas de corte.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ...installments.map((inst) {
            final progress =
                (inst.paidMonths / inst.totalMonths).clamp(0.0, 1.0);
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
                          child: Text(
                              '${inst.cardName} • ${inst.description}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          onPressed: () async {
                            if (user == null) return;
                            final updated = installments
                                .where((i) => i.id != inst.id)
                                .toList();
                            ref.read(installmentsProvider.notifier).state =
                                updated;
                            await CashStorageEngine.saveInstallments(
                                user.email, updated);
                          },
                        ),
                      ],
                    ),
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
                          label: Text(
                              'Cuota: ${currency.format(inst.monthlyQuota)}/mes',
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
                            onPressed: () async {
                              if (user == null) return;
                              final updated = installments
                                  .map((item) => item.id == inst.id
                                      ? item.copyWith(
                                          paidMonths: item.paidMonths + 1)
                                      : item)
                                  .toList();
                              ref.read(installmentsProvider.notifier).state =
                                  updated;
                              await CashStorageEngine.saveInstallments(
                                  user.email, updated);
                            },
                            child: const Text('Registrar Cuota Pagada'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],

        // SUB-VISTA 1: METAS DE AHORRO REALES
        if (subTab == 1) ...[
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Mis Metas de Ahorro',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              FilledButton.icon(
                onPressed: () => _openAddGoalModal(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('+ Nueva Meta'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (goals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Crea tu primera meta de ahorro (ej. Fondo de Emergencia, Vacaciones, Vehículo) pulsando "+ Nueva Meta".',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
          ...goals.map((g) {
            final pct =
                g.targetAmount > 0 ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0) : 0.0;
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
                          label: Text(g.deadline,
                              style: const TextStyle(fontSize: 11)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          onPressed: () async {
                            if (user == null) return;
                            final updated =
                                goals.where((i) => i.id != g.id).toList();
                            ref.read(savingsGoalsProvider.notifier).state =
                                updated;
                            await CashStorageEngine.saveGoals(
                                user.email, updated);
                          },
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
                          onPressed: () async {
                            if (user == null) return;
                            final updated = goals
                                .map((item) => item.id == g.id
                                    ? item.copyWith(
                                        currentAmount: item.currentAmount + 50)
                                    : item)
                                .toList();
                            ref.read(savingsGoalsProvider.notifier).state =
                                updated;
                            await CashStorageEngine.saveGoals(
                                user.email, updated);
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Abonar +\$50'),
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
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                      'Calculado en tiempo real sobre tus ingresos y gastos registrados',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              FilledButton.icon(
                onPressed: () {
                  final csv = _generateCsv(allTx);
                  Clipboard.setData(ClipboardData(text: csv));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            '✓ Sábana contable CSV copiada para Excel / Google Sheets.')),
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
                  const Text(
                      'Regla 50% Necesidades / 30% Deseos / 20% Ahorro',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  _RuleBar(
                    title: 'Necesidades Básicas (Meta <= 50%)',
                    amount: currency.format(needsSpent),
                    target: currency.format(income * 0.50),
                    ratio: income > 0
                        ? (needsSpent / (income * 0.50)).clamp(0.0, 1.0)
                        : 0.0,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 12),
                  _RuleBar(
                    title: 'Estilo de Vida y Ocio (Meta <= 30%)',
                    amount: currency.format(wantsSpent),
                    target: currency.format(income * 0.30),
                    ratio: income > 0
                        ? (wantsSpent / (income * 0.30)).clamp(0.0, 1.0)
                        : 0.0,
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
                  'Se detectaron ${microExpenses.length} micro-gastos (${currency.format(microTotal)}). Fuga anual proyectada: ${currency.format(microTotal * 12)}.'),
            ),
          ),
        ],
      ],
    );
  }
}

class _AddInstallmentForm extends ConsumerStatefulWidget {
  const _AddInstallmentForm();
  @override
  ConsumerState<_AddInstallmentForm> createState() =>
      _AddInstallmentFormState();
}

class _AddInstallmentFormState extends ConsumerState<_AddInstallmentForm> {
  final _cardCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _monthsCtrl = TextEditingController(text: '12');
  final _cutOffCtrl = TextEditingController(text: '15');
  final _dueDayCtrl = TextEditingController(text: '2');

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Registrar Nueva Compra Diferida',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        TextField(
          controller: _cardCtrl,
          decoration: const InputDecoration(
            labelText: 'Tarjeta de Crédito (Ej. Visa Pichincha, Diners)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            labelText: 'Descripción de la Compra',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _totalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto Total (USD)',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _monthsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Plazo (Meses)',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cutOffCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Día de Corte (1-31)',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _dueDayCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Día Máx. Pago (1-31)',
                ),
              ),
            ),
          ],
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
              child: FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final total = double.tryParse(
                          _totalCtrl.text.replaceAll(',', '.')) ??
                      0.0;
                  final months = int.tryParse(_monthsCtrl.text) ?? 12;
                  if (_cardCtrl.text.trim().isEmpty ||
                      _descCtrl.text.trim().isEmpty ||
                      total <= 0 ||
                      user == null) return;

                  final updated = [
                    ...ref.read(installmentsProvider),
                    CreditInstallmentModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      cardName: _cardCtrl.text.trim(),
                      description: _descCtrl.text.trim(),
                      totalAmount: total,
                      totalMonths: months,
                      paidMonths: 0,
                      cutOffDay:
                          (int.tryParse(_cutOffCtrl.text) ?? 15).clamp(1, 31),
                      paymentDueDay:
                          (int.tryParse(_dueDayCtrl.text) ?? 2).clamp(1, 31),
                    ),
                  ];
                  ref.read(installmentsProvider.notifier).state = updated;
                  await CashStorageEngine.saveInstallments(user.email, updated);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar Diferido'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddGoalForm extends ConsumerStatefulWidget {
  const _AddGoalForm();
  @override
  ConsumerState<_AddGoalForm> createState() => _AddGoalFormState();
}

class _AddGoalFormState extends ConsumerState<_AddGoalForm> {
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _initialCtrl = TextEditingController(text: '0');
  final _deadlineCtrl = TextEditingController(text: 'Dic 2026');

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Nueva Meta de Ahorro',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre de la Meta (Ej. Fondo de Emergencia, Viaje)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _targetCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto Objetivo (USD)',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _initialCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Ahorro Inicial Actual (USD)',
            prefixIcon: Icon(Icons.savings_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deadlineCtrl,
          decoration: const InputDecoration(
            labelText: 'Fecha Meta (Ej. Dic 2026)',
            prefixIcon: Icon(Icons.event),
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
              child: FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  final target = double.tryParse(
                          _targetCtrl.text.replaceAll(',', '.')) ??
                      0.0;
                  final current = double.tryParse(
                          _initialCtrl.text.replaceAll(',', '.')) ??
                      0.0;
                  if (_titleCtrl.text.trim().isEmpty ||
                      target <= 0 ||
                      user == null) return;

                  final updated = [
                    ...ref.read(savingsGoalsProvider),
                    SavingsGoalModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleCtrl.text.trim(),
                      targetAmount: target,
                      currentAmount: current,
                      deadline: _deadlineCtrl.text.trim(),
                    ),
                  ];
                  ref.read(savingsGoalsProvider.notifier).state = updated;
                  await CashStorageEngine.saveGoals(user.email, updated);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar Meta'),
              ),
            ),
          ],
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
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
// PESTAÑA 4: FAMILIA, INVITACIONES CON ENLACE REAL Y 3 PLANES EN USD
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

  Future<void> _sendEmailInvitation() async {
    final user = ref.read(authSessionProvider);
    if (user == null) return;

    final name = _inviteNameCtrl.text.trim();
    final email = _inviteEmailCtrl.text.trim().toLowerCase();
    if (name.isEmpty || email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Ingresa el nombre y un correo electrónico válido del familiar.')),
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

    final token = DateTime.now().millisecondsSinceEpoch.toString();
    final inviteUrl =
        'https://crisricky7.github.io/Cash/?invite=$token&email=$email';
    await Clipboard.setData(ClipboardData(text: inviteUrl));

    final updatedInvites = [
      ...pendingInvites,
      EmailInvitation(
        id: token,
        invitedName: name,
        invitedEmail: email,
        token: token,
      ),
    ];
    ref.read(pendingInvitationsProvider.notifier).state = updatedInvites;
    await CashStorageEngine.saveInvitations(user.email, updatedInvites);

    _inviteNameCtrl.clear();
    _inviteEmailCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✉️ Invitación creada para $email y enlace copiado al portapapeles.'),
        ),
      );
    }
  }

  Future<void> _confirmInvitationAccepted(EmailInvitation inv) async {
    final user = ref.read(authSessionProvider);
    if (user == null) return;

    final members = ref.read(householdMembersProvider);
    final pending = ref.read(pendingInvitationsProvider);

    final updatedPending = pending.where((i) => i.id != inv.id).toList();
    ref.read(pendingInvitationsProvider.notifier).state = updatedPending;
    await CashStorageEngine.saveInvitations(user.email, updatedPending);

    final updatedMembers = [
      ...members,
      HouseholdMember(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: inv.invitedName,
        email: inv.invitedEmail,
      ),
    ];
    ref.read(householdMembersProvider.notifier).state = updatedMembers;
    await CashStorageEngine.saveMembers(user.email, updatedMembers);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 ${inv.invitedName} se unió a la familia. ¡Modo Familiar activado y guardado!'),
        ),
      );
    }
  }

  void _openCheckoutForTier(SubscriptionTier targetTier, bool isAnnual) {
    showAdaptiveSheetOrDialog(
      context: context,
      child:
          _TierCheckoutSheet(targetTier: targetTier, initialIsAnnual: isAnnual),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider);
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                            ? 'Modo Familiar Activo (${members.length} personas compartiendo)'
                            : 'Modo Personal Activo (1 sola persona registrada)',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isFamily
                      ? 'Tienes más de 1 integrante activo en tu cuenta: el Modo Familiar (Verde Salvia) y el reparto equitativo están habilitados.'
                      : 'Solo estás tú en la cuenta: operas en Modo Personal (Azul Océano). Cuando invites a un familiar y se una, pasará a Modo Familiar automáticamente.',
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
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        'Cupos: ${members.length}/${currentTier.maxUsers}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _inviteNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Familiar',
                    prefixIcon: Icon(Icons.badge_outlined),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _inviteEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico del Familiar',
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
                    child: Text('Enviar Invitación por Correo'),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (pendingInvites.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Invitaciones Pendientes de Aceptación',
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const Text('Enlace de invitación enviado',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _confirmInvitationAccepted(inv),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Confirmar Aceptación'),
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
              title: Text(m.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${m.email} • Gastos registrados: ${currency.format(memberSpent)}'),
              trailing: m.isOwner
                  ? const Chip(label: Text('Titular'))
                  : IconButton(
                      icon: const Icon(Icons.person_remove_outlined,
                          color: Colors.red),
                      onPressed: () async {
                        if (user == null) return;
                        final updated =
                            members.where((item) => item.id != m.id).toList();
                        ref.read(householdMembersProvider.notifier).state =
                            updated;
                        await CashStorageEngine.saveMembers(
                            user.email, updated);
                      },
                    ),
            ),
          );
        }),

        if (isFamily && members.isNotEmpty) ...[
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

        const Text('Planes de Suscripción (Precios en USD)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Suscripción activa: $activeBillingText',
            style: const TextStyle(
                fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
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
          onSelectionChanged: (s) => ref
              .read(isAnnualBillingSelectedProvider.notifier)
              .state = s.first,
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  tier.maxUsers == 1
                                      ? '1 Usuario'
                                      : 'Hasta ${tier.maxUsers} Usuarios',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
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
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
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
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
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
                            ? 'Plan Activo (${tier.title})'
                            : 'Activar ${tier.title} (${isAnnualSelected ? "\$${tier.annualPrice.toStringAsFixed(2)} USD/año" : "\$${tier.monthlyPrice.toStringAsFixed(2)} USD/mes"})',
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
    final user = ref.watch(authSessionProvider);
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
              label:
                  Text('Mensual (\$${tier.monthlyPrice.toStringAsFixed(2)} USD)'),
            ),
            ButtonSegment<bool>(
              value: true,
              label: Text(
                  'Anual (\$${tier.annualPrice.toStringAsFixed(2)} USD • -33%)'),
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
                ? '• Pasarela: Payphone Cajita de Pagos V2\n• Total a pagar: \$${amountUsd.toStringAsFixed(2)} USD (Impuestos incluidos)\n• Confirmación en POST /api/button/V2/Confirm'
                : '• Pasarela: RevenueCat (Google Play / App Store)\n• Producto: $sku\n• Total a pagar: \$${amountUsd.toStringAsFixed(2)} USD',
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
                onPressed: () async {
                  if (user == null) return;
                  final label =
                      '${tier.title} (${_isAnnual ? "\$${tier.annualPrice.toStringAsFixed(2)} USD/año" : "\$${tier.monthlyPrice.toStringAsFixed(2)} USD/mes"}) vía ${_channel == "PAYPHONE_WEB" ? "Payphone" : "RevenueCat"}';
                  ref.read(subscriptionTierProvider.notifier).state = tier;
                  ref.read(isAnnualBillingSelectedProvider.notifier).state =
                      _isAnnual;
                  ref.read(activeBillingCycleTextProvider.notifier).state =
                      label;
                  await CashStorageEngine.saveTier(
                      user.email, tier, _isAnnual, label);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text('Activar por \$${amountUsd.toStringAsFixed(2)} USD'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// MODAL MANUAL (GASTO | INGRESO | RECARGAR BILLETERA / TRANSFERIR CON PERSISTENCIA)
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
  String? _selectedMember;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider);
    final members = ref.watch(householdMembersProvider);
    final accounts = ref.watch(accountsProvider);
    final allCategories = ref.watch(categoriesProvider);
    final filteredCategories =
        allCategories.where((c) => c.type == (_type == 1 ? 1 : 2)).toList();

    if (_selectedAccount == null ||
        !accounts.any((a) => a.name == _selectedAccount)) {
      _selectedAccount = accounts.isNotEmpty ? accounts.first.name : null;
    }
    if (_destinationAccount == null ||
        !accounts.any((a) => a.name == _destinationAccount) ||
        _destinationAccount == _selectedAccount) {
      final wallet =
          accounts.where((a) => a.type == 'Billetera Digital').firstOrNull;
      _destinationAccount =
          (wallet != null && wallet.name != _selectedAccount)
              ? wallet.name
              : (accounts.length > 1 ? accounts[1].name : _selectedAccount);
    }
    if (_selectedCategory == null ||
        !filteredCategories.any((c) => c.name == _selectedCategory)) {
      _selectedCategory =
          filteredCategories.isNotEmpty ? filteredCategories.first.name : null;
    }
    if (_selectedMember == null ||
        !members.any((m) => m.name == _selectedMember)) {
      _selectedMember =
          members.isNotEmpty ? members.first.name : (user?.fullName ?? 'Titular');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _type == 3
              ? 'Recargar Billetera / Transferir'
              : 'Registrar Movimiento Real',
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
        if (accounts.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _selectedAccount,
            isExpanded: true,
            decoration: InputDecoration(
              labelText:
                  _type == 3 ? 'Cuenta Origen' : 'Cuenta o Billetera Digital',
            ),
            items: accounts
                .map((a) => DropdownMenuItem(
                      value: a.name,
                      child: Text('${a.name} (\$${a.balance.toStringAsFixed(2)})',
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedAccount = v),
          ),
        const SizedBox(height: 12),
        if (_type == 3 && accounts.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _destinationAccount,
            isExpanded: true,
            decoration:
                const InputDecoration(labelText: 'Cuenta o Billetera Destino'),
            items: accounts
                .map((a) => DropdownMenuItem(
                      value: a.name,
                      child: Text('${a.name} (\$${a.balance.toStringAsFixed(2)})',
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _destinationAccount = v),
          )
        else if (filteredCategories.isNotEmpty)
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
        if (members.length > 1) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedMember,
            isExpanded: true,
            decoration:
                const InputDecoration(labelText: 'Registrado por Integrante'),
            items: members
                .map((m) => DropdownMenuItem(value: m.name, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedMember = v),
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
                onPressed: () async {
                  final amt = double.tryParse(
                          _amountCtrl.text.replaceAll(',', '.')) ??
                      0;
                  if (amt <= 0 || _selectedAccount == null || user == null) {
                    return;
                  }

                  final list = ref.read(transactionsListProvider);
                  List<TxItem> updatedTx;
                  List<AccountModel> updatedAcc;

                  if (_type == 3) {
                    if (_destinationAccount == null ||
                        _destinationAccount == _selectedAccount) return;
                    updatedTx = [
                      TxItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        description: _descCtrl.text.trim().isEmpty
                            ? 'Transferencia / Recarga'
                            : _descCtrl.text.trim(),
                        amount: amt,
                        type: 3,
                        categoryName: 'Transferencia',
                        accountName: _selectedAccount!,
                        destinationAccountName: _destinationAccount!,
                        memberName: _selectedMember ?? user.fullName,
                      ),
                      ...list,
                    ];
                    updatedAcc = accounts.map((acc) {
                      if (acc.name == _selectedAccount) {
                        return acc.copyWith(balance: acc.balance - amt);
                      }
                      if (acc.name == _destinationAccount) {
                        return acc.copyWith(balance: acc.balance + amt);
                      }
                      return acc;
                    }).toList();
                  } else {
                    updatedTx = [
                      TxItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        description: _descCtrl.text.trim().isEmpty
                            ? (_selectedCategory ?? 'Movimiento')
                            : _descCtrl.text.trim(),
                        amount: amt,
                        type: _type,
                        categoryName: _selectedCategory ?? 'General',
                        accountName: _selectedAccount!,
                        memberName: _selectedMember ?? user.fullName,
                      ),
                      ...list,
                    ];
                    updatedAcc = accounts.map((acc) {
                      if (acc.name == _selectedAccount) {
                        final delta = _type == 1 ? amt : -amt;
                        return acc.copyWith(balance: acc.balance + delta);
                      }
                      return acc;
                    }).toList();
                  }

                  ref.read(transactionsListProvider.notifier).state = updatedTx;
                  ref.read(accountsProvider.notifier).state = updatedAcc;
                  await CashStorageEngine.saveTransactions(
                      user.email, updatedTx);
                  await CashStorageEngine.saveAccounts(user.email, updatedAcc);

                  if (context.mounted) Navigator.pop(context);
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
