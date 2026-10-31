import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'menti_evolution.dart';
import 'menti_profile_storage.dart';
import 'menti_xp_store.dart';

/// MennyiMent? 3.3 – Menti Studio.
/// Megőrzi az eredeti avatar-, becenév- és fejfedőbeállításokat.
/// A mentett karaktercsalád és ruhaszett teljes PNG-jét használja.
/// A külön cserélhető ruharétegekhez később új grafika szükséges.
class AvatarPage extends StatefulWidget {
  const AvatarPage({super.key});

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage> {
  static const _avatarKey = 'mennyiment_avatar_v1';
  static const _nicknameKey = 'mennyiment_nickname_v1';
  static const _hatKey = 'mennyiment_hat_v1';
  static const _styleKey = MentiProfileStorage.studioBackgroundKey;
  static const _accessoryKey = 'mennyiment_accessory_v1';

  static const _mint = Color(0xFF76E4B8);
  static const _background = Color(0xFF0B1715);
  static const _panel = Color(0xFF172923);

  static const _moods = <String>['😎', '🤪', '🥳', '🤠', '😈', '🦸'];
  static const _moodNames = <String>[
    'Laza', 'Bolondos', 'Bulis', 'Cowboy', 'Vagány', 'Hős',
  ];
  static const _hatNames = <String>['Eredeti', 'Baseball', 'Bulikalap', 'Cowboy'];
  static const _hatIcons = <String>['👑', '🧢', '🥳', '🤠'];
  static const _styleNames = <String>['Éjszakai klub', 'Mentazöld', 'Arany VIP', 'Kozmosz'];
  static const _styleLevels = <int>[1, 1, 3, 5];
  static const _styleColors = <Color>[
    Color(0xFF462168), Color(0xFF145E4A), Color(0xFF8D651F), Color(0xFF263C80),
  ];
  static const _styleIcons = <IconData>[
    Icons.nightlife_rounded,
    Icons.spa_outlined,
    Icons.workspace_premium_outlined,
    Icons.auto_awesome_rounded,
  ];

  final TextEditingController _nameController = TextEditingController();
  bool _loading = true;
  String _nickname = 'Sörkapitány';
  int _mood = 0;
  int _hat = 0;
  int _style = 0;
  int _xp = 0;
  String _characterAsset = 'assets/images/menti_outfits/alap.png';
  int _reaction = 0;
  int _accessory = 0;
  static const _accessoryNames = <String>['Eredeti', 'Napszemüveg', 'Csillagjelvény', 'Fejhallgató'];
  static const _accessoryIcons = <String>['✨', '🕶️', '⭐', '🎧'];
  static const _accessoryLevels = <int>[1, 1, 2, 3];

  int get _level => 1 + _xp ~/ 50;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await MentiProfileStorage.migrate(prefs);
      final xpState = await MentiXpStore.load();
      final xp = xpState.xp;
      final level = xpState.level;
      var style = MentiProfileStorage.studioBackground(prefs);
      if (_styleLevels[style] > level) style = 0;
      if (!mounted) return;
      setState(() {
        _nickname = prefs.getString(_nicknameKey) ?? 'Sörkapitány';
        _mood = (prefs.getInt(_avatarKey) ?? 0).clamp(0, _moods.length - 1).toInt();
        _hat = (prefs.getInt(_hatKey) ?? 0).clamp(0, _hatNames.length - 1).toInt();
        _style = style;
        _xp = xp;
        _characterAsset = MentiProfileStorage.assetPath(prefs);
        final savedAccessory = (prefs.getInt(_accessoryKey) ?? 0).clamp(0, _accessoryNames.length - 1).toInt();
        _accessory = _accessoryLevels[savedAccessory] <= level ? savedAccessory : 0;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Menti Studio betöltési hiba: $error');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectMood(int index) async {
    setState(() { _mood = index; _reaction++; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_avatarKey, index);
  }

  Future<void> _selectHat(int index) async {
    setState(() => _hat = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hatKey, index);
  }

  Future<void> _selectStyle(int index) async {
    if (_level < _styleLevels[index]) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ez a háttér a(z) ${_styleLevels[index]}. szinten nyílik meg.'),
      ));
      return;
    }
    setState(() { _style = index; _reaction++; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_styleKey, index);
  }

  Future<void> _selectAccessory(int index) async {
    if (_level < _accessoryLevels[index]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ez a kiegészítő a(z) ${_accessoryLevels[index]}. szinten nyílik meg.')),
      );
      return;
    }
    setState(() { _accessory = index; _reaction++; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accessoryKey, index);
  }

  Widget _characterPreview() {
    // A régi sapka és ruha a PNG része. Ezeket nem fedi el egy új grafikával.
    // A következő három kiegészítő külön, ténylegesen látható réteg.
    const double size = 255;
    return SizedBox(
      width: 300,
      height: 315,
      child: Stack(
        alignment: Alignment.center,
        children: [
          MentiEvolution(
            key: const ValueKey('menti-studio-character'),
            assetPath: _characterAsset,
            size: size,
            level: _level,
            reaction: _reaction,
          ),
          if (_accessory == 1)
            Positioned(
              top: 85,
              left: 98,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -0.08,
                  child: Text('🕶️', style: TextStyle(fontSize: 72)),
                ),
              ),
            ),
          if (_accessory == 2)
            const Positioned(
              top: 174,
              left: 91,
              child: IgnorePointer(child: Text('⭐', style: TextStyle(fontSize: 43))),
            ),
          if (_accessory == 3)
            const Positioned(
              top: 57,
              left: 88,
              child: IgnorePointer(child: Text('🎧', style: TextStyle(fontSize: 108))),
            ),
        ],
      ),
    );
  }

  Future<void> _editNickname() async {
    _nameController.text = _nickname;
    final updated = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mi legyen a beceneved?'),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          maxLength: 25,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Becenév'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Mégse')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, _nameController.text.trim()),
            child: const Text('Mentés'),
          ),
        ],
      ),
    );
    if (!mounted || updated == null || updated.isEmpty) return;
    setState(() => _nickname = updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nicknameKey, updated);
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: child,
  );

  Widget _heading(String text, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      const SizedBox(height: 14),
    ],
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _styleColors[_style];
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(title: const Text('Menti Studio'), backgroundColor: _background),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [currentColor, _panel],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: _mint.withValues(alpha: 0.25)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                      child: Column(children: [
                        const Text('A TE MENTID',
                          style: TextStyle(color: _mint, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        const SizedBox(height: 10),
                        _characterPreview(),
                        const SizedBox(height: 8),
                        Text(_nickname,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Text('${_moods[_mood]} ${_moodNames[_mood]} hangulat',
                          style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 13),
                        OutlinedButton.icon(
                          onPressed: _editNickname,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Becenév szerkesztése'),
                        ),
                        const SizedBox(height: 4),
                        const Text('Koppints Mentire!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Menti fejlődése',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('$_xp XP', style: const TextStyle(color: _mint, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 13),
                      LinearProgressIndicator(
                        value: (_xp % 50) / 50,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(12),
                        color: _mint,
                        backgroundColor: Colors.white12,
                      ),
                      const SizedBox(height: 7),
                      Text('$_level. szint • ${50 - _xp % 50} XP a következő szintig',
                        style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 7),
                      const Text('XP a tudatos naplózáshoz kapcsolódó kihívásokból jár, nem az ivásért.',
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ])),
                    const SizedBox(height: 16),
                    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _heading('Hangulat', 'A választott hangulatjelvény az avatarod mellett jelenik meg.'),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (var i = 0; i < _moods.length; i++) ChoiceChip(
                          label: Text('${_moods[i]} ${_moodNames[i]}'),
                          selected: _mood == i,
                          onSelected: (_) => _selectMood(i),
                        ),
                      ]),
                    ])),
                    const SizedBox(height: 16),
                    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _heading('Menti világa', 'A háttér valóban megváltozik. Új világokat szintekkel nyithatsz meg.'),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (var i = 0; i < _styleNames.length; i++)
                          SizedBox(
                            width: 142,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () => _selectStyle(i),
                              child: Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: _styleColors[i],
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: _style == i ? _mint : Colors.white24,
                                    width: _style == i ? 2 : 1,
                                  ),
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Icon(_level < _styleLevels[i] ? Icons.lock_outline : _styleIcons[i],
                                    color: Colors.white, size: 27),
                                  const SizedBox(height: 10),
                                  Text(_styleNames[i], style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(_level < _styleLevels[i]
                                      ? '${_styleLevels[i]}. szinten nyílik' : _style == i ? 'Kiválasztva' : 'Elérhető',
                                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                ]),
                              ),
                            ),
                          ),
                      ]),
                    ])),
                    const SizedBox(height: 16),
                    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _heading('Viselhető kiegészítők',
                        'A kiválasztott kiegészítő azonnal megjelenik Mentin, és újraindítás után is megmarad.'),
                      Wrap(spacing: 9, runSpacing: 10, children: [
                        for (var i = 0; i < _accessoryNames.length; i++)
                          ChoiceChip(
                            selected: _accessory == i,
                            onSelected: (_) => _selectAccessory(i),
                            avatar: Text(_level < _accessoryLevels[i] ? '🔒' : _accessoryIcons[i]),
                            label: Text(_accessoryNames[i]),
                          ),
                      ]),
                      const SizedBox(height: 10),
                      const Text('A kiegészítők egyelőre a karakterképre illesztett grafikai rétegek, nem 3D ruhamodellek.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ])),
                    const SizedBox(height: 16),
                    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _heading('Fejfedők – gardróbterv',
                        'A választást elmentjük, de a Menti-képen még az eredeti koronás sapka látható. Cserélhető sapkákhoz külön képrétegeket készítünk.'),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (var i = 0; i < _hatNames.length; i++) ChoiceChip(
                          label: Text('${_hatIcons[i]} ${_hatNames[i]}'),
                          selected: _hat == i,
                          onSelected: (_) => _selectHat(i),
                        ),
                      ]),
                    ])),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
    );
  }
}
