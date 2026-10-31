import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Existing keys stay unchanged so that all prior character profiles survive.
class MentiCharacterProfile {
  static const styleKey = 'mennyiment_menti_style_v1';
  static const ageKey = 'mennyiment_age_group_v1';
  static const nameKey = 'mennyiment_character_name_v1';
  static const appearanceKey = 'mennyiment_menti_age_style_v1';
  static const completedKey = 'mennyiment_character_setup_complete_v1';
  static const accessoryKey = 'mennyiment_menti_accessory_v1';
  static const auraKey = 'mennyiment_menti_aura_v1';
  static const outfitKey = 'mennyiment_outfit_v2';
  static const moodKey = 'mennyiment_mood_v2';
  static const tintKey = 'mennyiment_character_color_v2';
}

class _MentiOutfit {
  const _MentiOutfit(this.label, this.subtitle, this.file, this.icon);
  final String label, subtitle, file;
  final IconData icon;
}

const _outfits = <_MentiOutfit>[
  _MentiOutfit('Alap szett', 'Kezdő stílus', 'alap.png', Icons.stars_outlined),
  _MentiOutfit('Buli szett', 'Vidám hangulat', 'buli.png', Icons.celebration_outlined),
  _MentiOutfit('Sport szett', 'Aktív napok', 'sport.png', Icons.fitness_center_outlined),
  _MentiOutfit('Üzleti szett', 'Elegáns', 'uzleti.png', Icons.work_outline),
  _MentiOutfit('Fesztivál szett', 'Színes stílus', 'fesztival.png', Icons.music_note_outlined),
  _MentiOutfit('Legendás szett', 'Prémium stílus', 'legendas.png', Icons.auto_awesome_outlined),
];

class MentiCharacterSetupPage extends StatefulWidget {
  const MentiCharacterSetupPage({super.key});
  @override
  State<MentiCharacterSetupPage> createState() => _MentiCharacterSetupPageState();
}

class _MentiCharacterSetupPageState extends State<MentiCharacterSetupPage> {
  static const _bg = Color(0xFF080F20);
  static const _panel = Color(0xFF131F36);
  static const _blue = Color(0xFF258BFF);
  static const _muted = Color(0xFFA7B8D2);
  String _style = 'Fiú Menti';
  String _age = '25–34';
  String _appearance = 'Fiatalos';
  String _accessory = 'Nincs';
  String _aura = 'Narancs';
  String _outfit = 'Alap szett';
  String _mood = 'Vidám';
  String _tint = 'Narancs';
  bool _saving = false;
  final _name = TextEditingController(text: 'Menti');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _style = p.getString(MentiCharacterProfile.styleKey) ?? _style;
      _age = p.getString(MentiCharacterProfile.ageKey) ?? _age;
      _appearance = p.getString(MentiCharacterProfile.appearanceKey) ?? _appearance;
      _accessory = p.getString(MentiCharacterProfile.accessoryKey) ?? _accessory;
      _aura = p.getString(MentiCharacterProfile.auraKey) ?? _aura;
      _outfit = p.getString(MentiCharacterProfile.outfitKey) ?? _outfit;
      _mood = p.getString(MentiCharacterProfile.moodKey) ?? _mood;
      _tint = p.getString(MentiCharacterProfile.tintKey) ?? _tint;
      _name.text = p.getString(MentiCharacterProfile.nameKey) ?? 'Menti';
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = _name.text.trim();
    if (_saving || n.isEmpty || n.length > 24) {
      if (n.isEmpty || n.length > 24) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('A karakter neve 1–24 karakter lehet.'),
        ));
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(MentiCharacterProfile.styleKey, _style);
      await p.setString(MentiCharacterProfile.ageKey, _age);
      await p.setString(MentiCharacterProfile.appearanceKey, _appearance);
      await p.setString(MentiCharacterProfile.nameKey, n);
      await p.setString(MentiCharacterProfile.accessoryKey, _accessory);
      await p.setString(MentiCharacterProfile.auraKey, _aura);
      await p.setString(MentiCharacterProfile.outfitKey, _outfit);
      await p.setString(MentiCharacterProfile.moodKey, _mood);
      await p.setString(MentiCharacterProfile.tintKey, _tint);
      await p.setBool(MentiCharacterProfile.completedKey, true);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mentési hiba: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color get _auraColor => switch (_aura) {
    'Kék' => const Color(0xFF3B9AFF),
    'Lila' => const Color(0xFFAF53FF),
    'Zöld' => const Color(0xFF23D69B),
    _ => const Color(0xFFFFA333),
  };

  Widget _section(String title, Widget content, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF263A56)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
        const SizedBox(height: 13),
        content,
      ]),
    );
  }

  Widget _pills(List<String> values, String selected, ValueChanged<String> onTap) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final v in values)
        ChoiceChip(
          label: Text(v), selected: selected == v,
          selectedColor: const Color(0xFF194F8B),
          backgroundColor: const Color(0xFF0C1628),
          labelStyle: TextStyle(color: Colors.white,
              fontWeight: selected == v ? FontWeight.bold : FontWeight.normal),
          side: BorderSide(color: selected == v ? _blue : const Color(0xFF33435A)),
          onSelected: (_) => setState(() => onTap(v)),
        ),
    ]);
  }

  String get _characterFile => switch (_style) {
    'Lány Menti' => 'lany.png',
    'Semleges Menti' => 'semleges.png',
    _ => 'fiu.png',
  };

  Widget _characterSelector() {
    const options = <(String, String)>[
      ('Fiú Menti', 'fiu.png'),
      ('Lány Menti', 'lany.png'),
      ('Semleges Menti', 'semleges.png'),
    ];
    return LayoutBuilder(builder: (context, layout) {
      final columns = layout.maxWidth < 320 ? 2 : 3;
      return GridView.count(
        crossAxisCount: columns,
        childAspectRatio: .72,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final option in options)
            InkWell(
              onTap: () => setState(() => _style = option.$1),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: _style == option.$1 ? const Color(0xFF164679) : _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _style == option.$1 ? _blue : const Color(0xFF33445E),
                      width: _style == option.$1 ? 2 : 1),
                ),
                padding: const EdgeInsets.all(5),
                child: Column(children: [
                  Expanded(child: Image.asset(
                    'assets/images/menti_characters/${option.$2}',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                      _missingAsset('assets/images/menti_characters/${option.$2}', compact: true),
                  )),
                  const SizedBox(height: 4),
                  Text(option.$1, textAlign: TextAlign.center, maxLines: 2,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
        ],
      );
    });
  }

  String get _outfitFile => _outfits.firstWhere(
      (x) => x.label == _outfit, orElse: () => _outfits.first).file;

  Widget _missingAsset(String assetPath, {bool compact = false}) {
    // A korábbi ikon-visszaesés elrejtette a hiányzó képeket.
    // Az asset elérési útját megmutatjuk, így könnyebb javítani a pubspec.yaml-t.
    return Container(
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF5A1B2D),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.broken_image_outlined, color: Colors.white,
            size: compact ? 23 : 46),
        const SizedBox(height: 5),
        Text('Hiányzó kép:', style: TextStyle(
            color: Colors.white, fontSize: compact ? 9 : 13)),
        Text(assetPath, maxLines: compact ? 3 : 5,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: compact ? 8 : 11)),
      ]),
    );
  }

  Widget _preview() {
    // Az eredeti hat ruhaszett egyelőre csak a klasszikus Fiú Mentihez készült.
    // A másik két karakter saját portrét mutat, hogy ne helyezzünk rájuk rossz ruhát.
    final image = _style == 'Fiú Menti'
        ? (_outfit == 'Alap szett'
            ? 'assets/images/menti.png'
            : 'assets/images/menti_outfits/$_outfitFile')
        : 'assets/images/menti_characters/$_characterFile';
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [
            _auraColor.withValues(alpha: .30), _panel, _bg,
          ], radius: 1.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _auraColor.withValues(alpha: .60)),
        ),
        child: Column(children: [
          const Text('SAJÁT MENTIM', style: TextStyle(
              fontWeight: FontWeight.w800, letterSpacing: 2, color: _muted)),
          const SizedBox(height: 10),
          SizedBox(height: 310, child: Image.asset(image,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _missingAsset(image),
          )),
          const SizedBox(height: 8),
          Text(_name.text.trim().isEmpty ? 'Menti' : _name.text.trim(),
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          Text(_style == 'Fiú Menti' ? '$_style  •  $_outfit'
                  : '$_style  •  Saját szettek előkészítés alatt',
              textAlign: TextAlign.center, style: const TextStyle(color: _muted)),
          const SizedBox(height: 7),
          Text('Hangulat: $_mood  ·  Aura: $_aura',
              style: TextStyle(color: _auraColor)),
        ]),
      ),
      const SizedBox(height: 12),
      _section('Karakterválasztás', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _characterSelector(),
        const SizedBox(height: 9),
        const Text('A lány és a semleges Menti külön előnézeti képet kapott. '
            'A hat teljes ruhaszett egyelőre a klasszikus Fiú Mentihez tartozik.',
            style: TextStyle(color: _muted, fontSize: 12)),
      ])),
      const SizedBox(height: 12),
      _section('Hangulat és arckifejezés', _pills(
          const ['Vidám', 'Kacsint', 'Nyugodt', 'Ünnepel'],
          _mood, (v) => _mood = v),
          subtitle: 'A hangulatválasztás menthető; külön képkockák később érkeznek.'),
      const SizedBox(height: 12),
      _section('Aura', Wrap(spacing: 10, runSpacing: 10, children: [
        for (final entry in <String, Color>{
          'Narancs': const Color(0xFFFFA333),
          'Kék': const Color(0xFF3B9AFF),
          'Lila': const Color(0xFFAF53FF),
          'Zöld': const Color(0xFF23D69B),
        }.entries)
          InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => setState(() => _aura = entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _aura == entry.key ? entry.value.withValues(alpha: .20) : _bg,
                border: Border.all(color: _aura == entry.key ? entry.value : const Color(0xFF324660),
                    width: _aura == entry.key ? 2 : 1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(radius: 7, backgroundColor: entry.value),
                const SizedBox(width: 7), Text(entry.key),
              ]),
            ),
          ),
      ])),
    ]);
  }

  Widget _wardrobe() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _section('Ruha szettek', GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _outfits.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 185, mainAxisSpacing: 9,
          crossAxisSpacing: 9, childAspectRatio: .74,
        ),
        itemBuilder: (context, i) {
          final outfit = _outfits[i];
          final selected = outfit.label == _outfit;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _outfit = outfit.label),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF164679) : _bg,
                border: Border.all(color: selected ? _blue : const Color(0xFF33445E),
                    width: selected ? 2 : 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                Expanded(child: Image.asset(
                  'assets/images/menti_outfits/${outfit.file}',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                    _missingAsset('assets/images/menti_outfits/${outfit.file}', compact: true),
                )),
                const SizedBox(height: 5),
                Text(outfit.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(outfit.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: _muted)),
              ]),
            ),
          );
        },
      ), subtitle: 'A hat szett a klasszikus Fiú Menti grafikája. Más karakterekhez a ruhák még készülnek.'),
      const SizedBox(height: 12),
      _section('Kiegészítők', _pills(
          const ['Nincs', 'Korona', 'Napszemüveg', 'Bulikalap', 'Csillag'],
          _accessory, (v) => _accessory = v),
          subtitle: 'A kiválasztást mentjük. A pontatlan kép-rárakást kikapcsoltuk.'),
      const SizedBox(height: 12),
      _section('Karakter további beállításai', Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Stílus', style: TextStyle(color: _muted)),
        const SizedBox(height: 7),
        _pills(const ['Fiatalos', 'Felnőttes', 'Veterán'],
            _appearance, (v) => _appearance = v),
        const SizedBox(height: 15),
        const Text('Karakter színe (későbbi 3D változat)', style: TextStyle(color: _muted)),
        const SizedBox(height: 7),
        _pills(const ['Narancs', 'Arany', 'Zöld', 'Kék', 'Rózsaszín', 'Lila'],
            _tint, (v) => _tint = v),
        const SizedBox(height: 15),
        const Text('Korosztály (18+)', style: TextStyle(color: _muted)),
        const SizedBox(height: 7),
        _pills(const ['18–24', '25–34', '35–44', '45+'],
            _age, (v) => _age = v),
        const SizedBox(height: 15),
        TextField(controller: _name, maxLength: 24,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Menti neve',
                border: OutlineInputBorder())),
      ])),
      const SizedBox(height: 15),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(backgroundColor: _blue,
            minimumSize: const Size.fromHeight(56)),
        icon: const Icon(Icons.check_circle_outline),
        label: Text(_saving ? 'Mentés…' : 'Saját Menti mentése',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 14),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(data: Theme.of(context).copyWith(
      scaffoldBackgroundColor: _bg,
      colorScheme: const ColorScheme.dark(primary: _blue, surface: _panel),
    ), child: Scaffold(
      appBar: AppBar(backgroundColor: _bg,
        title: const Text('MennyiMent?  ·  Saját Mentim',
            style: TextStyle(fontWeight: FontWeight.w800))),
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth > 800;
        return ListView(padding: const EdgeInsets.all(15), children: [
          Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Alakítsd ki Menti egyedi stílusát!',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Válassz karaktert, ruhaszettet és hangulatot.',
                  style: TextStyle(color: _muted)),
              const SizedBox(height: 17),
              if (wide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 4, child: _preview()),
                const SizedBox(width: 15),
                Expanded(flex: 6, child: _wardrobe()),
              ]) else ...[
                _preview(),
                const SizedBox(height: 15),
                _wardrobe(),
              ],
            ]),
          )),
        ]);
      }),
    ));
  }
}
