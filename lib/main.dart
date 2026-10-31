import 'dart:convert';
import 'dart:async';
import 'drink_journal.dart';
export 'drink_journal.dart';

import 'menti_progress.dart';
import 'menti_xp_store.dart';
import 'finance_center.dart';
import 'wellbeing_journal.dart';
import 'lifestyle_insights.dart';
import 'menti_week_report.dart';
import 'personal_goals.dart';
import 'savings_goals.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menti_reactions.dart';
import 'drink_catalog.dart';
import 'avatar.dart';
import 'menti_character_setup.dart';
import 'menti_profile_storage.dart';
import 'statistics.dart';
import 'dashboard_v2.dart';
import 'menti_evolution.dart';
import 'app_language.dart';
import 'l10n/generated/app_localizations.dart';
import 'menti_motion.dart';
import 'data_backup_page.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MennyiMentApp());
}

class MennyiMentApp extends StatefulWidget {
  const MennyiMentApp({super.key});

  @override
  State<MennyiMentApp> createState() => _MennyiMentAppState();
}

class _MennyiMentAppState extends State<MennyiMentApp> {
  late final AppLanguage language;
  @override
  void initState() { super.initState(); language = AppLanguage()..load(); }
  @override
  void dispose() { language.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: language, builder: (context, _) => AppLanguageScope(language: language, child: MaterialApp(
      builder: (context, child) => MentiMotionScope(child: child!),
      locale: language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: (locale, supported) => locale?.languageCode == 'en' ? const Locale('en') : const Locale('hu'),
      debugShowCheckedModeBanner: false,
      title: 'MennyiMent?',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C0A10),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0C0A10), foregroundColor: Colors.white, centerTitle: false),
        cardTheme: CardThemeData(color: const Color(0xFF21182B), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
        navigationBarTheme: NavigationBarThemeData(backgroundColor: const Color(0xFF17111E), indicatorColor: const Color(0xFF4B2959), labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, color: Colors.white))),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF21182B),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF60436C))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF493552))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF9E2C), width: 1.6)),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9E2C),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    )));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String mentiMessage =
    MentiReactions.message(MentiMood.welcome);

int mentiMessageIndex = 0;
int mentiReaction = 0;
void updateMentiMessage(MentiMood mood) {
  setState(() {
    if (mood == MentiMood.drinkAdded) {
  mentiReaction = (mentiReaction ~/ 3 + 1) * 3;
} else if (mood == MentiMood.statistics) {
  mentiReaction = (mentiReaction ~/ 3) * 3 + 1;
} else if (mood == MentiMood.goals) {
  mentiReaction = (mentiReaction ~/ 3) * 3 + 2;
} else {
  mentiReaction++;
}
    mentiMessageIndex++;
    mentiMessage = MentiReactions.message(
      mood,
      index: mentiMessageIndex,
    );
  });
}
  static const storageKey = 'mennyiment_drinks_v1';
  static const customDrinksKey = 'mennyiment_custom_drinks_v1';
  static const favoritesKey = 'mennyiment_favorites_v1';
  // 5.4: pontok kizárólag önellenőrzésre, soha nem alkoholfogyasztásra.
  final Set<String> _reflectionDays = {};
  bool _reflectionBusy = false;
  int _totalMentiXp = 0;

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  int get _reflectionXp => _totalMentiXp;
  int get _mentiLevel => 1 + _reflectionXp ~/ 50;
  double get _mentiLevelProgress => (_reflectionXp % 50) / 50;

  Future<void> _loadReflections() async {
    try {
      final state = await MentiXpStore.load();
      if (!mounted) return;
      setState(() {
        _totalMentiXp = state.xp;
        _reflectionDays
          ..clear()
          ..addAll(state.days);
      });
    } catch (error) {
      debugPrint('Menti XP betöltési hiba: $error');
    }
  }

  Future<void> _saveDailyReflection() async {
    final key = _dateKey(DateTime.now());
    if (_reflectionBusy || _reflectionDays.contains(key)) return;
    setState(() => _reflectionBusy = true);
    try {
      final state = await MentiXpStore.checkInToday();
      if (!mounted) return;
      setState(() {
        _totalMentiXp = state.xp;
        _reflectionDays
          ..clear()
          ..addAll(state.days);
        mentiReaction++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mai önellenőrzés rögzítve! +10 XP Mentinek.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A mentés nem sikerült. Próbáld újra!')),
        );
      }
      debugPrint('Menti XP mentési hiba: $error');
    } finally {
      if (mounted) setState(() => _reflectionBusy = false);
    }
  }

  final List<Drink> drinks = [];
  final List<CatalogDrink> customDrinks = [];
  final Set<String> favoriteDrinks = {};
  bool isLoading = true;
  bool _journalReady = false;
  bool _journalSaving = false;
  bool _recording = false;
  bool _pickerOpen = false;
  bool _customReady = false;
  bool _customSaving = false;
  String? _customSnapshot;
  final Map<CatalogDrink, Map<String, dynamic>> _customSources = {};
  bool _editingEntry = false;
  bool _deletingEntry = false;
  String? _journalSnapshot;
  String? _journalError;

  bool get _canWriteJournal => !isLoading && _journalReady && !_journalSaving;


  final options = <({String name, String emoji, int ml, double percent})>[
    (name: 'Sör', emoji: '🍺', ml: 500, percent: 5),
    (name: 'Bor', emoji: '🍷', ml: 150, percent: 12),
    (name: 'Pálinka', emoji: '🥃', ml: 50, percent: 50),
    (name: 'Fröccs', emoji: '🍹', ml: 200, percent: 6),
    (name: 'Unicum', emoji: '🥃', ml: 40, percent: 40),
  ];

  @override
  void initState() {
    super.initState();
    loadDrinks();
    loadCustomDrinks();
    loadFavorites();
    _loadReflections();
    _loadCharacterProfile();
  }

  Future<void> loadDrinks() async {
    if (_journalSaving) return;
    setState(() { isLoading = true; _journalReady = false; });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.get(storageKey);
      if (raw != null && raw is! String) throw const FormatException('Invalid journal type');
      final saved = raw as String?;
      final decoded = saved == null ? <dynamic>[] : jsonDecode(saved);
      if (decoded is! List) throw const FormatException('Invalid journal document');
      final loaded = decoded.map((item) {
        if (item is! Map) throw const FormatException('Invalid journal record');
        return Drink.fromJson(Map<String, dynamic>.from(item));
      }).toList();
      if (!mounted) return;
      setState(() {
        drinks..clear()..addAll(loaded);
        _journalSnapshot = saved;
        _journalReady = true;
        _journalError = null;
      });
    } catch (_) {
      if (mounted) { setState(() {
        _journalError = 'A napló nem tölthető be biztonságosan. Az eredeti adatokat megőriztük; a módosításokat letiltottuk.';
      }); }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadCustomDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.get(customDrinksKey);
      if (saved != null && saved is! String) throw const FormatException('Invalid custom drinks');
      final decoded = saved == null ? <dynamic>[] : jsonDecode(saved as String);
      if (decoded is! List) throw const FormatException('Invalid custom drinks');
      final sources = <CatalogDrink, Map<String, dynamic>>{};
      final loaded = decoded.map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        final verified = Drink.fromJson({...data, 'time': '2000-01-01T00:00:00.000'});
        final drink = CatalogDrink(
          name: verified.name,
          category: data['category'] as String? ?? 'Saját italok',
          emoji: data['emoji'] as String,
          ml: verified.ml,
          percent: verified.percent,
        );
        sources[drink] = data;
        return drink;
      }).toList();
      if (!mounted) return;
      setState(() {
        customDrinks..clear()..addAll(loaded);
        _customSources..clear()..addAll(sources);
        _customSnapshot = saved as String?;
        _customReady = true;
      });
    } catch (_) {
      if (mounted) setState(() { _customReady = false; });
    }
  }

  Future<void> saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(favoritesKey, favoriteDrinks.toList());
    } catch (error) {
      debugPrint('Kedvencek mentési hibája: $error');
    }
  }

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(favoritesKey) ?? [];
      if (!mounted) return;
      setState(() {
        favoriteDrinks
          ..clear()
          ..addAll(saved);
      });
    } catch (error) {
      debugPrint('Kedvencek betöltési hibája: $error');
    }
  }

  Future<bool> saveCustomDrinks(List<CatalogDrink> next) async {
    if (!_customReady || _customSaving) return false;
    _customSaving = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      if (prefs.get(customDrinksKey) != _customSnapshot) {
        _customReady = false;
        throw StateError('Custom drinks changed');
      }
      final data = next.map((drink) => _customSources[drink] ?? {
        'name': drink.name, 'category': drink.category, 'emoji': drink.emoji,
        'ml': drink.ml, 'percent': drink.percent,
      }).toList();
      final encoded = jsonEncode(data);
      if (!await prefs.setString(customDrinksKey, encoded)) throw StateError('Custom drink write failed');
      if (mounted) { setState(() {
        customDrinks..clear()..addAll(next);
        _customSnapshot = encoded;
      }); }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A saját italok módosítása nem sikerült; az eredeti adatokat megőriztük.')),
        );
      }
      return false;
    } finally { _customSaving = false; }
  }

  Future<bool> _persistDrinks(List<Drink> next) async {
    if (!_canWriteJournal) return false;
    setState(() => _journalSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      if (prefs.get(storageKey) != _journalSnapshot) {
        _journalReady = false;
        throw StateError('Journal changed outside this screen');
      }
      final encoded = jsonEncode(next.map((d) => d.toJson()).toList());
      if (!await prefs.setString(storageKey, encoded)) {
        throw StateError('Journal write failed');
      }
      if (mounted) { setState(() {
        drinks..clear()..addAll(next);
        _journalSnapshot = encoded;
        _journalError = null;
      }); }
      return true;
    } catch (_) {
      if (mounted) { setState(() {
        _journalError = 'A napló mentése nem sikerült. A módosítást nem alkalmaztuk. Próbáld újra vagy töltsd be újra a naplót.';
      }); }
      return false;
    } finally {
      if (mounted) setState(() => _journalSaving = false);
    }
  }

  Future<void> showAddDrinkDialog() async {
    if (!_customReady || _customSaving) return;
    var submitted = false;
    final nameController = TextEditingController();
    final mlController = TextEditingController();
    final percentController = TextEditingController();

    final newDrink = await showDialog<CatalogDrink>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Új saját ital'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ital neve',
                  hintText: 'Pl. Házi barackpálinka',
                ),
              ),
              TextField(
                controller: mlController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mennyiség (ml)',
                  hintText: '50',
                ),
              ),
              TextField(
                controller: percentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Alkoholfok (%)',
                  hintText: '50',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () {
              if (submitted) return;
              final name = nameController.text.trim();
              final ml = int.tryParse(mlController.text.trim());
              final percent = double.tryParse(
                percentController.text.trim().replaceAll(',', '.'),
              );
              if (name.isEmpty ||
                  ml == null ||
                  ml <= 0 ||
                  ml > 10000 ||
                  percent == null ||
                  !percent.isFinite ||
                  percent < 0 ||
                  percent > 100) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Adj meg érvényes adatokat!')),
                );
                return;
              }
              submitted = true;
              Navigator.pop(
                dialogContext,
                CatalogDrink(
                  name: name,
                  category: 'Saját italok',
                  emoji: '🥃',
                  ml: ml,
                  percent: percent,
                ),
              );
            },
            child: const Text('Mentés'),
          ),
        ],
      ),
    );

    // The dialog route may still animate out; don't dispose controllers
    // before the transition has completed.
    if (newDrink == null || !mounted) return;
    await saveCustomDrinks([...customDrinks, newDrink]);
  }

  Future<void> addDrink(int index) async {
    if (!_canWriteJournal) return;
    final d = options[index];
    if (await _persistDrinks([Drink(d.name, d.ml, d.percent), ...drinks]) && mounted) {
      updateMentiMessage(MentiMood.drinkAdded);
    }
  }

  Future<void> addCatalogDrink(CatalogDrink drink) async {
    if (!_canWriteJournal) return;
    if (await _persistDrinks([Drink(drink.name, drink.ml, drink.percent), ...drinks]) && mounted) {
      updateMentiMessage(MentiMood.drinkAdded);
    }
  }

  Future<void> editDrinkPrice(Drink drink) async {
    if (!_canWriteJournal || _editingEntry) return;
    _editingEntry = true;
    var submitted = false;
    try {
    final controller = TextEditingController(
      text: drink.priceFt?.toStringAsFixed(0) ?? '',
    );
    final result = await showDialog<double?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Ár megadása: ${drink.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Fizetett ár (Ft)',
            helperText: 'Üresen hagyva ismeretlen ár',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Mégse'),
          ),
          TextButton(
            onPressed: () {
              if (submitted) return;
              submitted = true;
              Navigator.pop(dialogContext, -1.0);
            },
            child: const Text('Ár törlése'),
          ),
          FilledButton(
            onPressed: () {
              if (submitted) return;
              if (controller.text.trim().isEmpty) {
                submitted = true;
                Navigator.pop(dialogContext, -1.0);
                return;
              }
              final value = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              if (value == null || !value.isFinite || value < 0 || value > 10000000) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Adj meg érvényes összeget!')),
                );
                return;
              }
              submitted = true;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Mentés'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    final index = drinks.indexOf(drink);
    if (index < 0) return;
    final next = List<Drink>.of(drinks);
    next[index] = drink.withPrice(result < 0 ? null : result);
    await _persistDrinks(next);
    } finally {
      _editingEntry = false;
    }
  }

  List<V2Drink> get dashboardDrinks => drinks.map((d) => V2Drink(
    name: d.name,
    time: d.time,
    grams: d.alcoholGrams,
    priceFt: d.priceFt,
  )).toList();

  String favoriteId(CatalogDrink drink) =>
      '${drink.name}|${drink.ml}|${drink.percent}';

  Future<void> _openStatistics() async {
    if (isLoading) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatisticsPage(
          drinks: drinks.map((d) => StatisticsDrink(
            name: d.name,
            ml: d.ml,
            percent: d.percent,
            time: d.time,
            priceFt: d.priceFt,
          )).toList(),
        ),
      ),
    );

    if (!mounted) return;
    updateMentiMessage(MentiMood.statistics);
  }

  Future<void> _openDashboard() async {
    if (isLoading) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardV2Page(drinks: dashboardDrinks),
      ),
    );

    if (!mounted) return;
    updateMentiMessage(MentiMood.goals);
  }

  void _openWellbeingJournal() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const WellbeingJournalPage(),
    ));
  }

  void _openLifestyleInsights() {
    if (isLoading) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LifestyleInsightsPage(drinks: drinks.map((d) => InsightDrink(
        time: d.time, grams: d.alcoholGrams, priceFt: d.priceFt,
      )).toList()),
    ));
  }

  void _openMentiWeekReport() {
    if (isLoading) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MentiWeekReportPage(drinks: drinks.map((d) => MentiWeekDrink(
        time: d.time, grams: d.alcoholGrams, priceFt: d.priceFt,
      )).toList()),
    ));
  }

  void _openPersonalGoals() {
    if (isLoading) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PersonalGoalsPage(
        drinks: drinks.map((d) => PersonalGoalDrink(
          time: d.time, priceFt: d.priceFt,
        )).toList(),
      ),
    ));
  }

  void _openSavingsGoals() {
    if (isLoading) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SavingsGoalsPage(drinks: drinks.map((d) =>
        SavingsDrink(time: d.time, priceFt: d.priceFt)).toList()),
    ));
  }

  void _openFinanceCenter() {
    if (isLoading) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => FinanceCenterPage(drinks: dashboardDrinks),
    ));
  }

  Future<void> _openMentiProgress() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => const MentiProgressPage(),
    ));
    if (mounted) await _loadReflections();
  }

  String _characterAsset = 'assets/images/menti_outfits/alap.png';
  String _characterName = 'Menti';
  String _characterAccessory = 'Nincs';
  String _characterAura = 'Narancs';

  Future<void> _loadCharacterProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await MentiProfileStorage.migrate(prefs);
      if (!mounted) return;
      setState(() {
        _characterAsset = MentiProfileStorage.assetPath(prefs);
        _characterName = prefs.getString(MentiCharacterProfile.nameKey) ?? 'Menti';
        _characterAccessory = prefs.getString(MentiCharacterProfile.accessoryKey) ?? 'Nincs';
        _characterAura = prefs.getString(MentiCharacterProfile.auraKey) ?? 'Narancs';
      });
      if (prefs.getBool(MentiCharacterProfile.completedKey) != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openCharacterSetup();
        });
      }
    } catch (error) {
      debugPrint('Menti-karakter betöltési hiba: $error');
    }
  }

  Future<void> _openCharacterSetup() async {
    final saved = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const MentiCharacterSetupPage()));
    if (saved == true && mounted) {
      await _loadReflections();
      final prefs = await SharedPreferences.getInstance();
      await MentiProfileStorage.migrate(prefs);
      if (!mounted) return;
      setState(() {
        _characterAsset = MentiProfileStorage.assetPath(prefs);
        _characterName = prefs.getString(MentiCharacterProfile.nameKey) ?? 'Menti';
        _characterAccessory = prefs.getString(MentiCharacterProfile.accessoryKey) ?? 'Nincs';
        _characterAura = prefs.getString(MentiCharacterProfile.auraKey) ?? 'Narancs';
      });
    }
  }

  void _openAvatar() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AvatarPage()));
  }

  static const Color _mint = Color(0xFFFF9E2C);
  static const Color _panel = Color(0xFF21182B);
  static const Color _muted = Color(0xFFD0C1D2);

  String _money(double amount) {
    final value = amount.round().toString();
    return value.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');
  }

  Widget _panelCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
    ),
    child: child,
  );

  Widget _statTile(String label, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.055), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: _mint, size: 20),
        const SizedBox(height: 12),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
      ]),
    ),
  );

  // A meglévő Drink JSON-formátum változatlan marad.
  Future<void> _recordCatalogDrink(CatalogDrink catalog) async {
    if (!_canWriteJournal || _recording) return;
    _recording = true;
    try {
    final result = await showModalBottomSheet<Drink>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _panel,
      builder: (_) => _DrinkDetailsSheet(drink: catalog),
    );
    if (!mounted || result == null) return;
    if (!await _persistDrinks([result, ...drinks])) return;
    if (!mounted) return;
    updateMentiMessage(MentiMood.drinkAdded);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.name} mentve a naplóba')),
    );
    } finally { _recording = false; }
  }

  Future<void> _openDrinkPicker() async {
    if (!_canWriteJournal || _pickerOpen || _recording) return;
    _pickerOpen = true;
    try {
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      backgroundColor: _panel,
      builder: (sheetContext) => SafeArea(child: FractionallySizedBox(
        heightFactor: 0.80,
        child: StatefulBuilder(builder: (context, refresh) {
          final favorites = drinkCatalog.where((d) => favoriteDrinks.contains(favoriteId(d))).toList();
          final catalog = [...favorites, ...drinkCatalog.where((d) => !favoriteDrinks.contains(favoriteId(d)))];
          return Column(children: [
            const Padding(padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('Ital hozzáadása', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)))),
            Expanded(child: ListView(children: [
              if (favorites.isNotEmpty) const Padding(padding: EdgeInsets.fromLTRB(20, 6, 20, 8),
                child: Text('⭐ Kedvenceid', style: TextStyle(color: _mint, fontWeight: FontWeight.bold))),
              ...catalog.map((drink) => ListTile(
                leading: Text(drink.emoji, style: const TextStyle(fontSize: 26)),
                title: Text(drink.name),
                subtitle: Text('${drink.ml} ml  •  ${drink.percent}%'),
                trailing: IconButton(
                  tooltip: 'Kedvenc',
                  icon: Icon(favoriteDrinks.contains(favoriteId(drink)) ? Icons.star : Icons.star_border,
                    color: Colors.amber),
                  onPressed: () {
                    final id = favoriteId(drink);
                    setState(() { if (!favoriteDrinks.add(id)) favoriteDrinks.remove(id); });
                    saveFavorites();
                    refresh(() {});
                  },
                ),
                onTap: !_canWriteJournal ? null : () {
                  if (_recording) return;
                  Navigator.pop(sheetContext);
                  _recordCatalogDrink(drink);
                },
              )),
              const Divider(),
              const Padding(padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text('Saját italok', style: TextStyle(color: _mint, fontWeight: FontWeight.bold))),
              ...customDrinks.map((drink) => ListTile(
                leading: Text(drink.emoji, style: const TextStyle(fontSize: 26)),
                title: Text(drink.name),
                subtitle: Text('${drink.ml} ml  •  ${drink.percent}%'),
                trailing: IconButton(tooltip: 'Saját ital törlése', icon: const Icon(Icons.delete_outline),
                  onPressed: !_customReady || _customSaving ? null : () async {
                    await saveCustomDrinks(List<CatalogDrink>.of(customDrinks)..remove(drink));
                    if (context.mounted) refresh(() {});
                  }),
                onTap: !_canWriteJournal ? null : () {
                  if (_recording) return;
                  Navigator.pop(sheetContext);
                  _recordCatalogDrink(drink);
                },
              )),
              if (!_customReady) const Padding(padding: EdgeInsets.all(16),
                child: Text('A saját italok nem tölthetők be biztonságosan; módosításuk letiltva.')),
              Padding(padding: const EdgeInsets.all(16), child: OutlinedButton.icon(
                onPressed: !_customReady || _customSaving ? null : () async {
                  Navigator.pop(sheetContext);
                  await showAddDrinkDialog();
                  if (mounted) _openDrinkPicker();
                }, icon: const Icon(Icons.add), label: const Text('Új saját ital létrehozása'))),
            ])),
          ]);
        }),
      )),
    );
    } finally { _pickerOpen = false; }
  }

  Future<void> _deleteEntry(Drink drink) async {
    if (!_canWriteJournal || _deletingEntry) return;
    _deletingEntry = true;
    try {
    var submitted = false;
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Bejegyzés törlése?'),
      content: Text('A(z) ${drink.name} bejegyzést eltávolítjuk a naplóból.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Mégse')),
        FilledButton(onPressed: () {
          if (submitted) return;
          submitted = true;
          Navigator.pop(ctx, true);
        }, child: const Text('Törlés')),
      ],
    ));
    if (confirmed != true || !mounted) return;
    await _persistDrinks(List<Drink>.of(drinks)..remove(drink));
    } finally { _deletingEntry = false; }
  }

  Widget _recentEntry(Drink drink) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(backgroundColor: const Color(0xFF392447),
      child: const Icon(Icons.local_bar_rounded, color: _mint)),
    title: Text(drink.name, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text('${drink.time.month}.${drink.time.day.toString().padLeft(2,'0')}. '
      '${drink.time.hour.toString().padLeft(2,'0')}:${drink.time.minute.toString().padLeft(2,'0')}  •  '
      '${drink.ml} ml  •  ${drink.alcoholGrams.toStringAsFixed(1)} g'),
    trailing: PopupMenuButton<String>(
      tooltip: 'Bejegyzés műveletei',
      onSelected: (value) {
        if (value == 'price') { editDrinkPrice(drink); }
        if (value == 'delete') { _deleteEntry(drink); }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'price', child: Text(drink.priceFt == null ? 'Ár megadása' : 'Ár: ${_money(drink.priceFt!)} Ft – szerkesztés')),
        const PopupMenuItem(value: 'delete', child: Text('Bejegyzés törlése')),
      ],
    ),
  );

  Widget _shortcut(String title, String subtitle, IconData icon,
      VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: const Color(0xFF21182B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF493552), width: 0.8),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: _mint, size: 26),
                const SizedBox(height: 13),
                Text(title, style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(
                    fontSize: 12, color: _muted),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = drinks.where((d) => d.time.year == now.year &&
        d.time.month == now.month && d.time.day == now.day).toList();
    final monthly = drinks.where((d) => d.time.year == now.year &&
        d.time.month == now.month).toList();
    final monthlyCost = monthly.fold<double>(0, (sum, d) => sum + (d.priceFt ?? 0));
    final monthlyUnknown = monthly.where((d) => d.priceFt == null).length;
    final todayCost = today.fold<double>(0, (sum, d) => sum + (d.priceFt ?? 0));
    final recent = drinks.toList()..sort((a, b) => b.time.compareTo(a.time));
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final loggedWeekDays = drinks
        .where((d) => !d.time.isBefore(weekStart) && d.time.isBefore(weekEnd))
        .map((d) => DateTime(d.time.year, d.time.month, d.time.day))
        .toSet().length;
    final todayUnknown = today.where((d) => d.priceFt == null).length;
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MennyiMent?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          const LanguageMenu(),
          IconButton(key: const ValueKey('open-data-backup'),
              tooltip: appStrings(context).backupTitle,
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const DataBackupPage())),
              icon: const Icon(Icons.save_alt_rounded)),
          IconButton(tooltip: appStrings(context).profile, onPressed: _openAvatar,
              icon: const Icon(Icons.account_circle_outlined)),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 1: _openDashboard(); break;
            case 2: _openLifestyleInsights(); break;
            case 3: _openAvatar(); break;
          }
        },
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: appStrings(context).home),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: appStrings(context).journal),
          NavigationDestination(icon: Icon(Icons.insights_rounded), label: appStrings(context).insights),
          NavigationDestination(icon: Icon(Icons.face_rounded), label: appStrings(context).menti),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: width < 380 ? 14 : 20,
                vertical: 16),
            children: [
              const Text('MENNYIMENT? 7.2 • A TE MENTID',
                  style: TextStyle(color: _mint, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              const SizedBox(height: 6),
              const Text('Szia! Hogy vagy ma?', style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              const Text('A mai tudatos döntéseid számítanak.',
                  style: TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(height: 12),
              _panelCard(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Stack(alignment: Alignment.topRight, children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: (_characterAura == 'Menta'
                                ? const Color(0xFF76E4B8)
                                : _characterAura == 'Lila'
                                  ? const Color(0xFFAB71E8)
                                  : const Color(0xFFFF9E2C)).withValues(alpha: .18),
                            blurRadius: 28,
                          )],
                        ),
                        child: MentiEvolution(
                          assetPath: _characterAsset,
                          reaction: mentiReaction,
                          level: _mentiLevel,
                          size: width < 380 ? 100 : 126,
                        ),
                      ),
                      if (_characterAccessory != 'Nincs')
                        Text(switch (_characterAccessory) {
                          'Korona' => '👑', 'Napszemüveg' => '🕶️',
                          'Bulikalap' => '🎉', 'Csillag' => '⭐', _ => '',
                        }, style: const TextStyle(fontSize: 25)),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_characterName • $_mentiLevel. szint',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text('Apró, tudatos lépésekből épül a fejlődés.',
                          style: TextStyle(color: _muted, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(mentiMessage, maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _mint, fontSize: 12)),
                        TextButton.icon(
                          onPressed: _openCharacterSetup,
                          icon: const Icon(Icons.palette_outlined, size: 17),
                          label: Text(appStrings(context).chooseMenti),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact)),
                        TextButton.icon(
                          onPressed: _openMentiProgress,
                          icon: const Icon(Icons.auto_awesome, size: 17),
                          label: Text(appStrings(context).mentiProgress),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 13),
                  Wrap(alignment: WrapAlignment.spaceBetween,
                    spacing: 8, runSpacing: 4,
                    children: [
                      Text('$_reflectionXp XP összesen',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${_reflectionXp % 50} / 50 XP a következő szintig',
                        style: const TextStyle(color: _muted, fontSize: 11)),
                    ]),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _mentiLevelProgress),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value, minHeight: 9,
                        backgroundColor: const Color(0xFF493552),
                        valueColor: const AlwaysStoppedAnimation<Color>(_mint)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _reflectionBusy ||
                          _reflectionDays.contains(_dateKey(DateTime.now()))
                          ? null : _saveDailyReflection,
                      icon: Icon(_reflectionDays.contains(_dateKey(DateTime.now()))
                        ? Icons.check_circle_outline : Icons.favorite_border_rounded),
                      label: Text(_reflectionDays.contains(_dateKey(DateTime.now()))
                        ? 'Mai önellenőrzés kész ✓'
                        : 'Mai tudatos pillanat  •  +10 XP'),
                    ),
                  ),
                  const Text('Az XP önellenőrzésért és tudatos heti kihívásokért jár, nem az elfogyasztott italokért.',
                    style: TextStyle(color: _muted, fontSize: 11)),
                ],
              )),
              const SizedBox(height: 12),
              Row(children: [
                _statTile('Mai ital', '${today.length}', Icons.local_bar_outlined),
                const SizedBox(width: 10),
                _statTile('Mai ismert költés', '${_money(todayCost)} Ft',
                    Icons.payments_outlined),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _statTile('Havi ismert költés', '${_money(monthlyCost)} Ft',
                    Icons.account_balance_wallet_outlined),
                const SizedBox(width: 10),
                _statTile('Heti naplózott nap', '$loggedWeekDays / 7',
                    Icons.calendar_today_outlined),
              ]),
              if (todayUnknown > 0 || monthlyUnknown > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Hiányzó italárak: ma $todayUnknown, ebben a hónapban '
                      '$monthlyUnknown. A költések részösszegek.',
                    style: const TextStyle(color: _muted, fontSize: 12)),
                ),
              const SizedBox(height: 12),
              if (_journalError != null) ...[
                Text(_journalError!, key: const ValueKey('journal-error')),
                TextButton(onPressed: _journalSaving || isLoading ? null : loadDrinks, child: const Text('Napló újratöltése')),
              ],
              FilledButton.icon(
                onPressed: _canWriteJournal ? _openDrinkPicker : null,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(appStrings(context).addDrink,
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                    backgroundColor: _mint,
                    foregroundColor: const Color(0xFF150D1C),
                    minimumSize: const Size(double.infinity, 54)),
              ),
              const SizedBox(height: 23),
              Text(appStrings(context).explore, style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _openFinanceCenter,
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: Text(appStrings(context).financeCenter)),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shortcut(appStrings(context).wellbeing, appStrings(context).wellbeingHint,
                    Icons.favorite_border_rounded, _openWellbeingJournal),
                const SizedBox(width: 10),
                _shortcut(appStrings(context).savings, appStrings(context).savingsHint,
                    Icons.savings_outlined, _openSavingsGoals),
              ]),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shortcut(appStrings(context).weeklyInsights, appStrings(context).weeklyInsightsHint,
                    Icons.insights_outlined, _openLifestyleInsights),
                const SizedBox(width: 10),
                _shortcut(appStrings(context).mentiProgress, appStrings(context).mentiProgressHint,
                    Icons.auto_awesome_outlined, _openMentiProgress),
              ]),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _shortcut(appStrings(context).goals, appStrings(context).goalsHint,
                    Icons.flag_outlined, _openDashboard),
                const SizedBox(width: 10),
                _shortcut(appStrings(context).statisticsNav, appStrings(context).statisticsHint,
                    Icons.bar_chart_rounded, _openStatistics),
              ]),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: isLoading ? null : _openPersonalGoals,
                  icon: const Icon(Icons.track_changes_rounded),
                  label: Text(appStrings(context).personalGoals),
                )),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _openMentiWeekReport,
                  icon: const Icon(Icons.auto_graph_rounded),
                  label: Text(appStrings(context).weeklyReport),
                )),
              const SizedBox(height: 24),
              Wrap(alignment: WrapAlignment.spaceBetween, spacing: 8, runSpacing: 4, children: [
                Text(appStrings(context).recentEntries, style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
                TextButton(onPressed: isLoading ? null : _openStatistics,
                    child: Text(appStrings(context).allEntries)),
              ]),
              const SizedBox(height: 8),
              _panelCard(child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : recent.isEmpty
                      ? const Text('Még nincs bejegyzés. Az első italodat '
                          'a fenti gombbal rögzítheted.',
                          style: TextStyle(color: _muted))
                      : Column(children: recent.take(4)
                          .map(_recentEntry).toList())),
              const SizedBox(height: 18),
              const Text('A napló önbevalláson alapul. Nem alkalmas '
                  'a józanság vagy a vezetési képesség megállapítására.',
                  style: TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

}

/// Menti folyamatosan lebeg és négy másodpercenként pislog.
class _FloatingMentiAnimated extends StatefulWidget {
  const _FloatingMentiAnimated();

  @override
  State<_FloatingMentiAnimated> createState() => __FloatingMentiAnimatedState();
}

class __FloatingMentiAnimatedState extends State<_FloatingMentiAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _movement;
  Timer? _blinkTimer;
  Timer? _openEyesTimer;
  bool _eyesClosed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _movement = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _eyesClosed = true);
      _openEyesTimer?.cancel();
      _openEyesTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _eyesClosed = false);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/menti.png'), context);
    precacheImage(const AssetImage('assets/images/menti_blink.png'), context);
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _openEyesTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _movement,
      child: Image.asset(
        _eyesClosed
            ? 'assets/images/menti_blink.png'
            : 'assets/images/menti.png',
        width: 230,
        height: 230,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _movement.value),
        child: child,
      ),
    );
  }
}


/// Legacy animation kept API-compatible, with timers disposed when motion stops.
class FloatingMenti extends StatelessWidget {
  const FloatingMenti({super.key});
  @override
  Widget build(BuildContext context) => MentiMotionScope.animateOf(context)
      ? const _FloatingMentiAnimated()
      : Image.asset('assets/images/menti.png', width: 230, height: 230,
          fit: BoxFit.contain);
}

/// 4.3: mennyiség, alkoholfok és ár egy lépésben.
/// Az ár opcionális; a hiányzó ár nem jelent 0 Ft-os vásárlást.
class _DrinkDetailsSheet extends StatefulWidget {
  const _DrinkDetailsSheet({required this.drink});
  final CatalogDrink drink;

  @override
  State<_DrinkDetailsSheet> createState() => _DrinkDetailsSheetState();
}

class _DrinkDetailsSheetState extends State<_DrinkDetailsSheet> {
  late final TextEditingController _ml;
  late final TextEditingController _percent;
  late final TextEditingController _price;
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _ml = TextEditingController(text: widget.drink.ml.toString());
    _percent = TextEditingController(text: widget.drink.percent.toString());
    _price = TextEditingController();
  }

  @override
  void dispose() {
    _ml.dispose();
    _percent.dispose();
    _price.dispose();
    super.dispose();
  }

  double? _number(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.drink.emoji} ${widget.drink.name}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Rögzítsd, amit ténylegesen fogyasztottál.',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ml,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Mennyiség (ml)', prefixIcon: Icon(Icons.local_drink_outlined)),
                  validator: (value) {
                    final n = int.tryParse((value ?? '').trim());
                    return n == null || n <= 0 || n > 10000
                        ? 'Adj meg 1 és 10 000 ml közötti mennyiséget.' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _percent,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Alkoholfok (%)', prefixIcon: Icon(Icons.percent)),
                  validator: (value) {
                    final n = _number(value ?? '');
                    return n == null || !n.isFinite || n < 0 || n > 100
                        ? 'Adj meg 0 és 100 közötti alkoholfokot.' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Fizetett ár (Ft) – opcionális',
                    helperText: 'Üresen hagyva ismeretlen árként mentjük.',
                    prefixIcon: Icon(Icons.payments_outlined)),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return null;
                    final n = _number(value!);
                    return n == null || !n.isFinite || n < 0 || n > 10000000
                        ? 'Adj meg érvényes árat (0–10 000 000 Ft).' : null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mentés a naplóba'),
                    onPressed: () {
                      if (_submitted || !_formKey.currentState!.validate()) return;
                      _submitted = true;
                      final priceText = _price.text.trim();
                      Navigator.of(context).pop(Drink(
                        widget.drink.name,
                        int.parse(_ml.text.trim()),
                        _number(_percent.text)!,
                        priceFt: priceText.isEmpty ? null : _number(priceText),
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
