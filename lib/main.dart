import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const NotesProApp());

const String appTitle = 'ملاحظاتي اليومية';
const String appVersion = 'V2';
const String developerEmail = 'fastunlocked2017@gmail.com';
const Color seedColor = Color(0xFF7C3AED);
const Color accentColor = Color(0xFFEC4899);

class NoteItem {
  final String title;
  final String body;
  final String tag;
  final bool favorite;
  final DateTime createdAt;

  const NoteItem({required this.title, required this.body, required this.tag, required this.favorite, required this.createdAt});

  String encode() => [title, body, tag, favorite ? '1' : '0', createdAt.toIso8601String()].join('|||');

  static NoteItem decode(String raw) {
    final p = raw.split('|||');
    return NoteItem(
      title: p.isNotEmpty ? p[0] : 'ملاحظة',
      body: p.length > 1 ? p[1] : '',
      tag: p.length > 2 ? p[2] : 'عام',
      favorite: p.length > 3 ? p[3] == '1' : false,
      createdAt: p.length > 4 ? DateTime.tryParse(p[4]) ?? DateTime.now() : DateTime.now(),
    );
  }

  NoteItem copyWith({String? title, String? body, String? tag, bool? favorite}) => NoteItem(title: title ?? this.title, body: body ?? this.body, tag: tag ?? this.tag, favorite: favorite ?? this.favorite, createdAt: createdAt);
}

class NotesProApp extends StatelessWidget {
  const NotesProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFFAF7FF),
        fontFamily: 'Arial',
      ),
      home: const Directionality(textDirection: TextDirection.rtl, child: SplashScreen()),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Directionality(textDirection: TextDirection.rtl, child: HomeScreen())));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)], begin: Alignment.topRight, end: Alignment.bottomLeft)),
      child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 106, height: 106, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(36), border: Border.all(color: Colors.white.withValues(alpha: .30))), child: const Text('📝', style: TextStyle(fontSize: 54))),
        const SizedBox(height: 22),
        const Text(appTitle, style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('أفكارك مرتبة، محفوظة، وسهلة الوصول', style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: 16)),
        const SizedBox(height: 34),
        const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
      ])),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  String filter = 'الكل';
  bool reminders = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 21, minute: 0);
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  String tag = 'عام';
  List<NoteItem> notes = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList('notes_v2');
    setState(() {
      notes = (saved == null || saved.isEmpty) ? _starter() : saved.map(NoteItem.decode).toList();
      reminders = p.getBool('notes_reminders') ?? true;
      reminderTime = TimeOfDay(hour: p.getInt('notes_h') ?? 21, minute: p.getInt('notes_m') ?? 0);
    });
  }

  List<NoteItem> _starter() => [
    NoteItem(title: 'فكرة تطبيق جديد', body: 'تسجيل فكرة سريعة ثم تطويرها لاحقًا إلى خطة واضحة.', tag: 'أفكار', favorite: true, createdAt: DateTime.now()),
    NoteItem(title: 'موعد مهم', body: 'مراجعة المهام المسائية قبل النوم.', tag: 'مهام', favorite: false, createdAt: DateTime.now()),
  ];

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('notes_v2', notes.map((e) => e.encode()).toList());
    await p.setBool('notes_reminders', reminders);
    await p.setInt('notes_h', reminderTime.hour);
    await p.setInt('notes_m', reminderTime.minute);
  }

  void _sound([bool alert = false]) => SystemSound.play(alert ? SystemSoundType.alert : SystemSoundType.click);

  void _addNote() {
    final title = titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) return;
    setState(() {
      notes.insert(0, NoteItem(title: title.isEmpty ? 'ملاحظة بدون عنوان' : title, body: body, tag: tag, favorite: false, createdAt: DateTime.now()));
      titleCtrl.clear();
      bodyCtrl.clear();
    });
    _save();
    _sound();
  }

  void _toggleFav(int i) { setState(() => notes[i] = notes[i].copyWith(favorite: !notes[i].favorite)); _save(); _sound(); }
  void _delete(int i) { final old = notes[i]; setState(() => notes.removeAt(i)); _save(); _sound(true); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف ${old.title}'), action: SnackBarAction(label: 'تراجع', onPressed: () { setState(() => notes.insert(i, old)); _save(); }))); }

  List<NoteItem> get visibleNotes {
    final q = searchCtrl.text.trim();
    return notes.where((n) {
      final f = filter == 'الكل' || (filter == 'المفضلة' && n.favorite) || n.tag == filter;
      final s = q.isEmpty || n.title.contains(q) || n.body.contains(q) || n.tag.contains(q);
      return f && s;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _notesPage(), _archivePage(), _settingsPage(), _aboutPage()];
    return Scaffold(
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[index])),
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) { setState(() => index = v); _sound(); }, destinations: const [
        NavigationDestination(icon: Icon(Icons.auto_awesome_rounded), label: 'الرئيسية'),
        NavigationDestination(icon: Icon(Icons.edit_note_rounded), label: 'الملاحظات'),
        NavigationDestination(icon: Icon(Icons.folder_special_rounded), label: 'الأرشيف'),
        NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'الإعدادات'),
        NavigationDestination(icon: Icon(Icons.info_rounded), label: 'عن'),
      ]),
    );
  }

  Widget _dashboard() => ListView(padding: const EdgeInsets.all(16), children: [
    _hero(), const SizedBox(height: 14),
    Row(children: [Expanded(child: _stat('كل الملاحظات', '${notes.length}', Icons.notes_rounded)), const SizedBox(width: 10), Expanded(child: _stat('المفضلة', '${notes.where((e) => e.favorite).length}', Icons.star_rounded))]),
    const SizedBox(height: 14), _sectionTitle('تدوين سريع'), _editorCard(compact: true),
    const SizedBox(height: 14), _sectionTitle('آخر الأفكار'), ...notes.take(3).map((n) => _noteTile(notes.indexOf(n))),
  ]);

  Widget _notesPage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageHeader('الملاحظات', 'اكتب أفكارك وصنفها وابحث عنها بسرعة.'),
    _editorCard(compact: false), const SizedBox(height: 12),
    TextField(controller: searchCtrl, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: 'بحث في العنوان أو النص', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none))),
    const SizedBox(height: 12),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['الكل', 'المفضلة', 'عام', 'أفكار', 'مهام', 'دراسة', 'عمل'].map((f) => Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f)))).toList())),
    const SizedBox(height: 12),
    if (visibleNotes.isEmpty) _empty('لا توجد ملاحظات مطابقة.'),
    ...visibleNotes.map((n) => _noteTile(notes.indexOf(n))),
  ]);

  Widget _archivePage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageHeader('الأرشيف الذكي', 'ملخص سريع لتصنيفاتك وملاحظاتك المهمة.'),
    _tagSummary(), const SizedBox(height: 12),
    ...notes.where((e) => e.favorite).map((n) => _noteTile(notes.indexOf(n))),
    if (notes.where((e) => e.favorite).isEmpty) _empty('لا توجد ملاحظات مفضلة بعد.'),
  ]);

  Widget _settingsPage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageHeader('الإعدادات', 'اضبط تجربة التذكير والكتابة.'),
    ProCard(child: SwitchListTile(value: reminders, onChanged: (v) { setState(() => reminders = v); _save(); }, title: const Text('تذكير كتابة ملاحظة'), subtitle: Text(reminders ? 'مفعل عند ${reminderTime.format(context)}' : 'متوقف'), secondary: const Icon(Icons.notifications_active_rounded))),
    const SizedBox(height: 10),
    ProCard(child: ListTile(leading: const Icon(Icons.schedule_rounded), title: const Text('وقت التذكير'), subtitle: Text(reminderTime.format(context)), trailing: const Icon(Icons.chevron_left_rounded), onTap: () async { final t = await showTimePicker(context: context, initialTime: reminderTime); if (t != null) { setState(() => reminderTime = t); _save(); } })),
    const SizedBox(height: 10),
    ProCard(child: ListTile(leading: const Icon(Icons.copy_all_rounded), title: const Text('نسخ كل الملاحظات'), subtitle: const Text('مناسب للنسخ الاحتياطي اليدوي'), onTap: () { Clipboard.setData(ClipboardData(text: notes.map((e) => '${e.title}\n${e.body}\n#${e.tag}').join('\n\n---\n\n'))); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الملاحظات'))); })),
  ]);

  Widget _aboutPage() => ListView(padding: const EdgeInsets.all(16), children: [
    _pageHeader('عن التطبيق', 'دفتر ملاحظات عربي أنيق وخفيف.'),
    ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 60, height: 60, alignment: Alignment.center, decoration: BoxDecoration(gradient: const LinearGradient(colors: [seedColor, accentColor]), borderRadius: BorderRadius.circular(20)), child: const Text('📝', style: TextStyle(fontSize: 30))), const SizedBox(width: 12), const Expanded(child: Text('$appTitle $appVersion', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)))]),
      const SizedBox(height: 12), const Text('تطبيق ملاحظات احترافي يحافظ على البساطة، مع بحث، تصنيفات، مفضلة، نسخ احتياطي يدوي، وتذكير يومي اختياري.'),
    ])),
    const SizedBox(height: 12),
    ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('مراسلة المطور', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const SelectableText(developerEmail), const SizedBox(height: 12),
      FilledButton.icon(onPressed: () { Clipboard.setData(const ClipboardData(text: 'السلام عليكم، لدي ملاحظة حول تطبيق ملاحظاتي اليومية:\n\nالبريد: fastunlocked2017@gmail.com')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ رسالة المطور'))); }, icon: const Icon(Icons.copy_all_rounded), label: const Text('نسخ الرسالة للمطور')),
    ])),
  ]);

  Widget _hero() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)], begin: Alignment.topRight, end: Alignment.bottomLeft), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: seedColor.withValues(alpha: .22), blurRadius: 24, offset: const Offset(0, 12))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(22)), child: const Text('📝', style: TextStyle(fontSize: 34))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text(appTitle, style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('مساحة منظمة للأفكار اليومية والمهام السريعة', style: TextStyle(color: Colors.white.withValues(alpha: .86)))]))]),
    const SizedBox(height: 18),
    Row(children: [_heroMini('اليوم', '${notes.where((e) => _sameDay(e.createdAt, DateTime.now())).length}'), const SizedBox(width: 10), _heroMini('تصنيفات', '${notes.map((e) => e.tag).toSet().length}')]),
  ]));

  Widget _editorCard({required bool compact}) => ProCard(child: Column(children: [
    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الملاحظة', border: InputBorder.none)),
    if (!compact) TextField(controller: bodyCtrl, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'نص الملاحظة', border: InputBorder.none)),
    if (!compact) Row(children: [Expanded(child: DropdownButtonFormField<String>(value: tag, decoration: const InputDecoration(labelText: 'التصنيف'), items: ['عام', 'أفكار', 'مهام', 'دراسة', 'عمل'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => tag = v ?? tag))), const SizedBox(width: 10), FilledButton.icon(onPressed: _addNote, icon: const Icon(Icons.save_rounded), label: const Text('حفظ'))]),
    if (compact) Align(alignment: AlignmentDirectional.centerEnd, child: FilledButton.icon(onPressed: _addNote, icon: const Icon(Icons.add_rounded), label: const Text('إضافة'))),
  ]));

  Widget _noteTile(int i) { final n = notes[i]; return Padding(padding: const EdgeInsets.only(bottom: 10), child: ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(n.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), IconButton(onPressed: () => _toggleFav(i), icon: Icon(n.favorite ? Icons.star_rounded : Icons.star_border_rounded, color: n.favorite ? accentColor : null)), IconButton(onPressed: () => _delete(i), icon: const Icon(Icons.delete_outline_rounded))]),
    if (n.body.isNotEmpty) Text(n.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.45)),
    const SizedBox(height: 10), Row(children: [Chip(label: Text(n.tag)), const Spacer(), Text(_date(n.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12))]),
  ]))); }

  Widget _tagSummary() { final tags = notes.map((e) => e.tag).toSet().toList(); return ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('التصنيفات', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: tags.map((t) => Chip(label: Text('$t (${notes.where((e) => e.tag == t).length})'))).toList())])); }
  Widget _stat(String t, String v, IconData icon) => ProCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: seedColor), const SizedBox(height: 8), Text(v, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), Text(t)]));
  Widget _heroMini(String a, String b) => Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a, style: TextStyle(color: Colors.white.withValues(alpha: .78))), Text(b, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))])));
  Widget _pageHeader(String title, String sub) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(sub, style: TextStyle(color: Colors.grey.shade700))]));
  Widget _sectionTitle(String s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
  Widget _empty(String text) => ProCard(child: Center(child: Padding(padding: const EdgeInsets.all(10), child: Text(text, style: TextStyle(color: Colors.grey.shade700)))));
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

class ProCard extends StatelessWidget {
  final Widget child;
  const ProCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .055), blurRadius: 22, offset: const Offset(0, 10))]), child: child);
}
