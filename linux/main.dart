import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'drink_catalog.dart';
import 'avatar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MennyiMentApp());
}

class MennyiMentApp extends StatelessWidget {
  const MennyiMentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MennyiMent?',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF10121B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB66CFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Drink {
  final String name;
  final int ml;
  final double percent;
  final DateTime time;

  Drink(this.name, this.ml, this.percent, {DateTime? time})
      : time = time ?? DateTime.now();

  double get alcoholGrams => ml * percent / 100 * 0.789;

  Map<String, dynamic> toJson() => {
        'name': name,
        'ml': ml,
        'percent': percent,
        'time': time.toIso8601String(),
      };

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      json['name'] as String,
      (json['ml'] as num).toInt(),
      (json['percent'] as num).toDouble(),
      time: DateTime.parse(json['time'] as String),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const storageKey = 'mennyiment_drinks_v1';
  static const customDrinksKey = 'mennyiment_custom_drinks_v1';
  static const favoritesKey = 'mennyiment_favorites_v1';

  final List<Drink> drinks = [];
  final List<CatalogDrink> customDrinks = [];
  final Set<String> favoriteDrinks = {};
  bool isLoading = true;

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
  }

  Future<void> loadDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);
      if (saved != null) {
        final decoded = jsonDecode(saved) as List<dynamic>;
        final loaded = decoded
            .map((item) => Drink.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        if (!mounted) return;
        setState(() {
          drinks
            ..clear()
            ..addAll(loaded);
        });
      }
    } catch (error) {
      debugPrint('Betöltési hiba: $error');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadCustomDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(customDrinksKey);
      if (saved == null) return;
      final decoded = jsonDecode(saved) as List<dynamic>;
      final loaded = decoded.map((item) {
        final data = Map<String, dynamic>.from(item as Map);
        return CatalogDrink(
          name: data['name'] as String,
          category: data['category'] as String? ?? 'Saját italok',
          emoji: data['emoji'] as String,
          ml: (data['ml'] as num).toInt(),
          percent: (data['percent'] as num).toDouble(),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        customDrinks
          ..clear()
          ..addAll(loaded);
      });
    } catch (error) {
      debugPrint('Saját italok betöltési hibája: $error');
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

  Future<void> saveCustomDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = customDrinks.map((drink) => {
            'name': drink.name,
            'category': drink.category,
            'emoji': drink.emoji,
            'ml': drink.ml,
            'percent': drink.percent,
          }).toList();
      await prefs.setString(customDrinksKey, jsonEncode(data));
    } catch (error) {
      debugPrint('Saját italok mentési hibája: $error');
    }
  }

  Future<void> saveDrinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(drinks.map((d) => d.toJson()).toList());
      final saved = await prefs.setString(storageKey, encoded);
      if (!saved) debugPrint('Nem sikerült menteni az italnaplót.');
    } catch (error) {
      debugPrint('Mentési hiba: $error');
    }
  }

  Future<void> showAddDrinkDialog() async {
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
    setState(() => customDrinks.add(newDrink));
    await saveCustomDrinks();
  }

  void addDrink(int index) {
    if (isLoading) return;
    final d = options[index];
    setState(() => drinks.insert(0, Drink(d.name, d.ml, d.percent)));
    saveDrinks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${d.name} hozzáadva!')),
    );
  }

  void addCatalogDrink(CatalogDrink drink) {
    if (isLoading) return;
    setState(() {
      drinks.insert(0, Drink(drink.name, drink.ml, drink.percent));
    });
    saveDrinks();
  }

  String favoriteId(CatalogDrink drink) =>
      '${drink.name}|${drink.ml}|${drink.percent}';

  @override
  Widget build(BuildContext context) {
    final grams = drinks.fold<double>(0, (sum, d) => sum + d.alcoholGrams);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🍻 MennyiMent?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF10121B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AvatarPage(),
                ),
              );
            },
            icon: const Icon(Icons.face),
            label: const Text('😎 Avatárom'),
          ),
          const SizedBox(height: 20),

          const Center(
  child: Column(
    children: [
      Text(
        'MENTI TESZT 123',
        style: TextStyle(
          color: Colors.red,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
      FloatingMenti(),
    ],
  ),
),
          const SizedBox(height: 16),
          const Text(
            'Na, mennyi ment ma?',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kövesd az italokat egyetlen koppintással.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Card(
            color: const Color(0xFF28213D),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Text('Napló', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  Text(
                    '${drinks.length} ital',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${grams.toStringAsFixed(1)} g tiszta alkohol',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Magyar italválaszték',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...drinkCatalog.map(
            (drink) => Card(
              child: ListTile(
                leading: Text(drink.emoji, style: const TextStyle(fontSize: 30)),
                title: Text(drink.name),
                subtitle: Text('${drink.ml} ml • ${drink.percent}%'),
                trailing: IconButton(
                  icon: Icon(
                    favoriteDrinks.contains(favoriteId(drink))
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                  ),
                  tooltip: 'Kedvenc megjelölése',
                  onPressed: () {
                    final id = favoriteId(drink);
                    setState(() {
                      if (!favoriteDrinks.add(id)) {
                        favoriteDrinks.remove(id);
                      }
                    });
                    saveFavorites();
                  },
                ),
                onTap: isLoading ? null : () => addCatalogDrink(drink),
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            '⭐ Saját italaim',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: showAddDrinkDialog,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Saját ital hozzáadása'),
          ),
          const SizedBox(height: 20),
          ...customDrinks.map(
            (drink) => Card(
              child: ListTile(
                leading: Text(drink.emoji, style: const TextStyle(fontSize: 30)),
                title: Text(drink.name),
                subtitle: Text('${drink.ml} ml • ${drink.percent}%'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Saját ital törlése',
                  onPressed: () {
                    setState(() => customDrinks.remove(drink));
                    saveCustomDrinks();
                  },
                ),
                onTap: isLoading ? null : () {
                  addCatalogDrink(drink);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${drink.name} hozzáadva a naplóhoz!')),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Mit ittál?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...List.generate(options.length, (index) {
            final d = options[index];
            return Card(
              child: ListTile(
                leading: Text(d.emoji, style: const TextStyle(fontSize: 30)),
                title: Text(d.name),
                subtitle: Text('${d.ml} ml • ${d.percent}%'),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: isLoading ? null : () => addDrink(index),
              ),
            );
          }),
          const SizedBox(height: 25),
          const Text(
            'Fogyasztási napló',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (drinks.isEmpty)
            const Text(
              'Még nem adtál hozzá italt.',
              style: TextStyle(color: Colors.white70),
            ),
          ...drinks.map(
            (d) => ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
              title: Text(d.name),
              subtitle: Text(
                '${d.ml} ml • ${d.time.hour.toString().padLeft(2, '0')}:${d.time.minute.toString().padLeft(2, '0')}',
              ),
              trailing: Text('${d.alcoholGrams.toStringAsFixed(1)} g'),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'A napló tájékoztató jellegű. Nem alkalmas a vezetési képesség vagy a józanság megállapítására.',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

/// Menti folyamatosan lebeg és négy másodpercenként pislog.
class FloatingMenti extends StatefulWidget {
  const FloatingMenti({super.key});

  @override
  State<FloatingMenti> createState() => _FloatingMentiState();
}

class _FloatingMentiState extends State<FloatingMenti>
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
