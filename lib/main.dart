import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const App());
const appTitle = 'ملاحظاتي اليومية';
const appVersion = 'V4';
const developerEmail = 'fastunlocked2017@gmail.com';
const seed = Color(0xFF6D28D9);
const accent = Color(0xFFDB2777);

class Note {
  final String title;
  final String body;
  final String tag;
  final bool fav;
  final DateTime date;
  const Note(this.title, this.body, this.tag, this.fav, this.date);
  String encode() => [title, body, tag, fav ? '1' : '0', date.toIso8601String()].join('|||');
  static Note decode(String raw) { final p = raw.split('|||'); return Note(p.isNotEmpty ? p[0] : 'ملاحظة', p.length > 1 ? p[1] : '', p.length > 2 ? p[2] : 'عام', p.length > 3 ? p[3] == '1' : false, p.length > 4 ? DateTime.tryParse(p[4]) ?? DateTime.now() : DateTime.now()); }
  Note copyFav() => Note(title, body, tag, !fav, date);
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: appTitle,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: seed), scaffoldBackgroundColor: const Color(0xFFFAF7FF), fontFamily: 'Arial'),
    home: const Directionality(textDirection: TextDirection.rtl, child: Home()),
  );
}

class Home extends StatefulWidget { const Home({super.key}); @override State<Home> createState() => _HomeState(); }

class _HomeState extends State<Home> {
  int tab = 0;
  String filter = 'الكل';
  String tag = 'عام';
  bool reminders = true;
  TimeOfDay reminderTime = const TimeOfDay(hour: 21, minute: 0);
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  List<Note> notes = [];

  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final p = await SharedPreferences.getInstance(); final saved = p.getStringList('notes_v4') ?? p.getStringList('notes_v3') ?? p.getStringList('notes_v2'); setState(() { notes = (saved == null || saved.isEmpty) ? starter() : saved.map(Note.decode).toList(); reminders = p.getBool('notes_reminders') ?? true; reminderTime = TimeOfDay(hour: p.getInt('notes_h') ?? 21, minute: p.getInt('notes_m') ?? 0); }); }
  List<Note> starter() => [Note('فكرة تطبيق جديد', 'تسجيل فكرة سريعة ثم تطويرها لاحقًا.', 'أفكار', true, DateTime.now()), Note('موعد مهم', 'مراجعة المهام المسائية.', 'مهام', false, DateTime.now())];
  Future<void> save() async { final p = await SharedPreferences.getInstance(); await p.setStringList('notes_v4', notes.map((e) => e.encode()).toList()); await p.setBool('notes_reminders', reminders); await p.setInt('notes_h', reminderTime.hour); await p.setInt('notes_m', reminderTime.minute); }

  List<Note> get visible { final q = searchCtrl.text.trim(); return notes.where((n) { final f = filter == 'الكل' || (filter == 'المفضلة' && n.fav) || n.tag == filter; final s = q.isEmpty || n.title.contains(q) || n.body.contains(q) || n.tag.contains(q); return f && s; }).toList(); }
  void addNote() { final title = titleCtrl.text.trim(); final body = bodyCtrl.text.trim(); if (title.isEmpty && body.isEmpty) return; setState(() { notes.insert(0, Note(title.isEmpty ? 'ملاحظة بدون عنوان' : title, body, tag, false, DateTime.now())); titleCtrl.clear(); bodyCtrl.clear(); }); save(); SystemSound.play(SystemSoundType.click); }
  void toggleFav(Note n) { final i = notes.indexOf(n); if (i < 0) return; setState(() => notes[i] = notes[i].copyFav()); save(); }
  void remove(Note n) { final i = notes.indexOf(n); setState(() => notes.remove(n)); save(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف ${n.title}'), action: SnackBarAction(label: 'تراجع', onPressed: () { setState(() => notes.insert(i < 0 ? 0 : i, n)); save(); }))); }
  void copyAll() { Clipboard.setData(ClipboardData(text: notes.map((e) => '${e.title}\n${e.body}\n#${e.tag}').join('\n\n---\n\n'))); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الملاحظات'))); }

  @override Widget build(BuildContext context) { final pages = [dashboard(), notesPage(), archivePage(), settingsPage(), aboutPage()]; return Scaffold(body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[tab])), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.auto_awesome_rounded), label: 'الرئيسية'), NavigationDestination(icon: Icon(Icons.edit_note_rounded), label: 'الملاحظات'), NavigationDestination(icon: Icon(Icons.folder_special_rounded), label: 'الأرشيف'), NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'الإعدادات'), NavigationDestination(icon: Icon(Icons.info_rounded), label: 'عن')]),); }

  Widget dashboard() => ListView(padding: const EdgeInsets.all(16), children: [hero(), const SizedBox(height: 14), Row(children: [Expanded(child: stat('كل الملاحظات', '${notes.length}', Icons.notes_rounded)), const SizedBox(width: 10), Expanded(child: stat('المفضلة', '${notes.where((e) => e.fav).length}', Icons.star_rounded))]), const SizedBox(height: 14), section('تدوين سريع'), editorCard(compact: true), const SizedBox(height: 14), section('آخر الأفكار'), if (notes.isEmpty) empty('لا توجد ملاحظات بعد'), ...notes.take(3).map(tile)]);
  Widget notesPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('الملاحظات', 'اكتب أفكارك وصنفها وابحث عنها بسرعة.'), editorCard(compact: false), const SizedBox(height: 12), TextField(controller: searchCtrl, onChanged: (_) => setState(() {}), decoration: input('بحث في العنوان أو النص', Icons.search_rounded)), const SizedBox(height: 12), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['الكل', 'المفضلة', 'عام', 'أفكار', 'مهام', 'دراسة', 'عمل'].map((f) => Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f)))).toList())), const SizedBox(height: 12), if (visible.isEmpty) empty('لا توجد ملاحظات مطابقة'), ...visible.map(tile)]);
  Widget archivePage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('الأرشيف الذكي', 'ملخص سريع لتصنيفاتك وملاحظاتك المهمة.'), tagSummary(), const SizedBox(height: 12), FilledButton.icon(onPressed: notes.isEmpty ? null : copyAll, icon: const Icon(Icons.copy_all_rounded), label: const Text('نسخ كل الملاحظات')), const SizedBox(height: 12), ...notes.where((e) => e.fav).map(tile), if (notes.where((e) => e.fav).isEmpty) empty('لا توجد مفضلة بعد')]);
  Widget settingsPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('الإعدادات', 'اضبط تجربة التذكير والكتابة.'), card(SwitchListTile(value: reminders, onChanged: (v) { setState(() => reminders = v); save(); }, title: const Text('تذكير كتابة ملاحظة'), subtitle: Text(reminders ? 'مفعل عند ${reminderTime.format(context)}' : 'متوقف'), secondary: const Icon(Icons.notifications_active_rounded))), const SizedBox(height: 10), card(ListTile(leading: const Icon(Icons.schedule_rounded), title: const Text('وقت التذكير'), subtitle: Text(reminderTime.format(context)), trailing: const Icon(Icons.chevron_left_rounded), onTap: () async { final t = await showTimePicker(context: context, initialTime: reminderTime); if (t != null) { setState(() => reminderTime = t); save(); } }))]);
  Widget aboutPage() => ListView(padding: const EdgeInsets.all(16), children: [pageHeader('عن التطبيق', 'دفتر ملاحظات عربي أنيق وخفيف.'), card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('$appTitle $appVersion', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('تحسين بصري V4، بحث، تصنيفات، مفضلة، نسخ احتياطي يدوي، وحفظ محلي مع قراءة بيانات V2/V3 القديمة.'), const SizedBox(height: 12), const SelectableText(developerEmail)]))]);

  Widget hero() => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFFDB2777)], begin: Alignment.topRight, end: Alignment.bottomLeft), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: seed.withValues(alpha: .20), blurRadius: 28, offset: const Offset(0, 14))]), child: const Text('$appTitle V4', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)));
  Widget editorCard({required bool compact}) => card(Column(children: [TextField(controller: titleCtrl, decoration: input('العنوان', Icons.title_rounded)), if (!compact) const SizedBox(height: 8), if (!compact) TextField(controller: bodyCtrl, minLines: 4, maxLines: 7, decoration: input('نص الملاحظة', Icons.notes_rounded)), if (!compact) const SizedBox(height: 8), if (!compact) DropdownButtonFormField<String>(value: tag, decoration: input('التصنيف', Icons.category_rounded), items: ['عام', 'أفكار', 'مهام', 'دراسة', 'عمل'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => tag = v ?? tag)), const SizedBox(height: 10), Align(alignment: AlignmentDirectional.centerEnd, child: FilledButton.icon(onPressed: addNote, icon: const Icon(Icons.save_rounded), label: const Text('حفظ')))]));
  Widget tile(Note n) => Padding(padding: const EdgeInsets.only(bottom: 10), child: card(Row(children: [CircleAvatar(backgroundColor: seed.withValues(alpha: .12), child: const Icon(Icons.note_alt_rounded, color: seed)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), Text(n.body.isEmpty ? '#${n.tag}' : '${n.body}  #${n.tag}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700))])), IconButton(onPressed: () => toggleFav(n), icon: Icon(n.fav ? Icons.star_rounded : Icons.star_border_rounded, color: n.fav ? Colors.amber : null)), IconButton(onPressed: () => remove(n), icon: const Icon(Icons.delete_outline_rounded))])));
  Widget tagSummary() => card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: ['عام', 'أفكار', 'مهام', 'دراسة', 'عمل'].map((t) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Text(t), const Spacer(), Text('${notes.where((e) => e.tag == t).length}', style: const TextStyle(fontWeight: FontWeight.w900))]))).toList()));
  Widget stat(String t, String v, IconData icon) => card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: seed), const SizedBox(height: 8), Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), Text(t)]));
  Widget pageHeader(String title, String sub) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(sub, style: TextStyle(color: Colors.grey.shade700))]));
  Widget section(String s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(s, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
  Widget empty(String text) => card(Center(child: Padding(padding: const EdgeInsets.all(10), child: Text(text, style: TextStyle(color: Colors.grey.shade700)))));
  InputDecoration input(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none));
  Widget card(Widget child) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .045), blurRadius: 22, offset: const Offset(0, 10))]), child: child);
}
