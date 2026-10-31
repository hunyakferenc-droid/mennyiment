import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menti_profile_storage.dart';
import 'menti_character_catalog.dart';
import 'menti_xp_store.dart';

/// Existing profile keys are preserved; the colliding style key is migrated.
class MentiCharacterProfile {
  static const styleKey = MentiProfileStorage.characterStyleKey;
  static const ageKey = 'mennyiment_age_group_v1';
  static const nameKey = 'mennyiment_character_name_v1';
  static const appearanceKey = 'mennyiment_menti_age_style_v1';
  static const completedKey = 'mennyiment_character_setup_complete_v1';
  static const accessoryKey = 'mennyiment_menti_accessory_v1';
  static const auraKey = 'mennyiment_menti_aura_v1';
  static const outfitKey = MentiProfileStorage.outfitKey;
  static const moodKey = 'mennyiment_mood_v2';
  static const tintKey = 'mennyiment_character_color_v2';
}

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
  MentiCharacterFamily _style = MentiCharacterFamily.boy;
  String _age = '25–34';
  String _appearance = 'Fiatalos';
  String _accessory = 'Nincs';
  String _aura = 'Narancs';
  MentiOutfit _outfit = MentiOutfit.basic;
  bool _preserveUnknownStyle = false;
  bool _preserveUnknownOutfit = false;
  String _mood = 'Vidám';
  String _tint = 'Narancs';
  bool _saving = false;
  int _reflectionXp = 0;
  int get _level => 1 + _reflectionXp ~/ 50;
  final _name = TextEditingController(text: 'Menti');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    await MentiProfileStorage.migrate(p);
    final xpState = await MentiXpStore.load();
    if (!mounted) return;
    final savedStyle = p.get(MentiCharacterProfile.styleKey);
    final savedOutfit = p.get(MentiCharacterProfile.outfitKey);
    setState(() {
      _reflectionXp = xpState.xp;
      _style = MentiCharacterFamily.resolve(savedStyle) ?? MentiCharacterFamily.boy;
      _preserveUnknownStyle = savedStyle != null && MentiCharacterFamily.resolve(savedStyle) == null;
      _age = p.getString(MentiCharacterProfile.ageKey) ?? _age;
      _appearance = p.getString(MentiCharacterProfile.appearanceKey) ?? _appearance;
      _accessory = p.getString(MentiCharacterProfile.accessoryKey) ?? _accessory;
      _aura = p.getString(MentiCharacterProfile.auraKey) ?? _aura;
      _outfit = MentiOutfit.resolve(savedOutfit) ?? MentiOutfit.basic;
      _preserveUnknownOutfit = savedOutfit != null && MentiOutfit.resolve(savedOutfit) == null;
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
      // An unrelated profile edit must not replace an unknown saved choice.
      if (!_preserveUnknownStyle) {
        await p.setString(MentiCharacterProfile.styleKey, _style.id);
      }
      await p.setString(MentiCharacterProfile.ageKey, _age);
      await p.setString(MentiCharacterProfile.appearanceKey, _appearance);
      await p.setString(MentiCharacterProfile.nameKey, n);
      await p.setString(MentiCharacterProfile.accessoryKey, _accessory);
      await p.setString(MentiCharacterProfile.auraKey, _aura);
      if (!_preserveUnknownOutfit) {
        await p.setString(MentiCharacterProfile.outfitKey, _outfit.id);
      }
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

  String get _previewAsset => _style.assetFor(_outfit);

  Widget _previewImage(String image) {
    // Teljes karakterkép, nagyítás és levágás nélkül.
    // A prototípus PNG-k saját háttere és feliratai továbbra is a kép részei.
    return SizedBox(
      height: 310,
      width: double.infinity,
      child: Image.asset(
        image,
        cacheWidth: (400 * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(1, 1086),
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) => _missingAsset(image),
      ),
    );
  }

  Widget _characterSelector() {
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
          for (final option in MentiCharacterFamily.values)
            InkWell(
              onTap: () => setState(() {
                _style = option;
                _preserveUnknownStyle = false;
              }),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: _style == option ? const Color(0xFF164679) : _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _style == option ? _blue : const Color(0xFF33445E),
                      width: _style == option ? 2 : 1),
                ),
                padding: const EdgeInsets.all(5),
                child: Column(children: [
                  Expanded(child: Image.asset(
                    option.selectorAsset,
                    cacheWidth: (180 * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(1, 512),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                      _missingAsset(option.selectorAsset, compact: true),
                  )),
                  const SizedBox(height: 4),
                  Text(option.label, textAlign: TextAlign.center, maxLines: 2,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
        ],
      );
    });
  }

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
    final image = _previewAsset;
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
          _previewImage(image),
          const SizedBox(height: 8),
          Text(_name.text.trim().isEmpty ? 'Menti' : _name.text.trim(),
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          Text('${_style.label}  •  ${_outfit.label}',
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
        const Text('Mindhárom karakter nagy előnézete követi a kiválasztott ruhaszettet. '
            'A képek részletgazdagsága karakterenként eltérhet.',
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
      _section('Menti fejlődése', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$_level. szint  •  $_reflectionXp XP',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 9),
        LinearProgressIndicator(value: (_reflectionXp % 50) / 50, minHeight: 9,
          color: _blue, backgroundColor: _bg, borderRadius: BorderRadius.circular(10)),
        const SizedBox(height: 7),
        Text('${_reflectionXp % 50}/50 XP a következő szintig',
          style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 8),
        const Text('XP a napi önellenőrzésért jár, nem az alkoholfogyasztásért.',
          style: TextStyle(color: _muted, fontSize: 12)),
      ])),
      const SizedBox(height: 12),
      _section('Ruha szettek', GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: MentiOutfit.values.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 185, mainAxisSpacing: 9,
          crossAxisSpacing: 9, childAspectRatio: .74,
        ),
        itemBuilder: (context, i) {
          final outfit = MentiOutfit.values[i];
          final selected = outfit == _outfit;
          final unlocked = _level >= outfit.requiredLevel || selected;
          final selectable = unlocked;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: selectable ? () => setState(() {
              _outfit = outfit;
              _preserveUnknownOutfit = false;
            })
              : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('A ${outfit.label} a(z) ${outfit.requiredLevel}. szinten nyílik meg.'))),
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
                  _style.assetFor(outfit),
                  cacheWidth: (185 * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(1, 1086),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                    _missingAsset(_style.assetFor(outfit), compact: true),
                )),
                const SizedBox(height: 5),
                Text(outfit.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(unlocked ? outfit.subtitle : '🔒 ${outfit.requiredLevel}. szinttől',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: selectable ? _muted : Colors.orangeAccent)),
              ]),
            ),
          );
        },
      ), subtitle: _style == MentiCharacterFamily.neutral
          ? 'A szettkártyák prototípusok; nagyban a teljes alapkarakter látszik.'
          : 'Alap, Buli és Sport: 1. szint • Üzleti: 2. • Fesztivál: 3. • Legendás: 5.'),
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
