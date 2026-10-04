import 'package:suspecto/features/game/data/local/word_translations.dart';
import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';

String translate(BuildContext context, String text) {
  final store = StoreScope.maybeOf(context);
  final language = store?.languageConfig.resolve(store.language).code ?? 'en';
  if (language != 'ar') {
    return text;
  }
  if (arabicWords.containsKey(text)) {
    return arabicWords[text]!;
  }
  if (_arabic.containsKey(text)) {
    return _arabic[text]!;
  }
  final patterns = <(RegExp, String Function(RegExpMatch))>[
    (RegExp(r'^Pass to (.+)$'), (m) => 'مرر الهاتف إلى ${m[1]}'),
    (RegExp(r'^I am (.+)$'), (m) => 'أنا ${m[1]}'),
    (RegExp(r'^Player (\d+)$'), (m) => 'اللاعب ${m[1]}'),
    (RegExp(r'^Remove player (\d+)$'), (m) => 'حذف اللاعب ${m[1]}'),
    (RegExp(r'^Add player \((\d+)/20\)$'), (m) => 'إضافة لاعب (${m[1]}/20)'),
    (RegExp(r'^(\d+) min$'), (m) => '${m[1]} دقائق'),
    (RegExp(r'^(\d+) votes$'), (m) => '${m[1]} أصوات'),
    (
      RegExp(r'^Card (\d+) of (\d+)\. Everyone else, look away\.$'),
      (m) => 'البطاقة ${m[1]} من ${m[2]}. على الآخرين عدم النظر.'
    ),
    (
      RegExp(r'^Vote (\d+) of (\d+)\. Choose your suspect privately\.$'),
      (m) => 'التصويت ${m[1]} من ${m[2]}. اختر المشتبه به سراً.'
    ),
    (
      RegExp(
          r'^(.+) starts\. Give one clue each, then discuss who is bluffing\. Keep the word secret\.$'),
      (m) =>
          'يبدأ ${m[1]}. يقدم كل لاعب تلميحاً، ثم ناقشوا من يخادع. لا تكشفوا الكلمة.'
    ),
    (RegExp(r'^Imposters: (.+)$'), (m) => 'المخادعون: ${m[1]}'),
  ];
  for (final (pattern, replacement) in patterns) {
    final match = pattern.firstMatch(text);
    if (match != null) {
      return replacement(match);
    }
  }
  return text;
}

class LocalText extends StatelessWidget {
  const LocalText(this.data,
      {super.key, this.style, this.textAlign, this.maxLines, this.overflow});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  @override
  Widget build(BuildContext context) => Text(translate(context, data),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow);
}

const _arabic = <String, String>{
  'Trust no one.\nSuspect everyone.': 'لا تثق بأحد.\nاشك في الجميع.',
  'The secret word is out. Someone is bluffing.':
      'الجميع يعرف الكلمة السرية. أحدهم يخادع.',
  'One phone. A room full of suspects.': 'هاتف واحد. ومجموعة من المشتبه بهم.',
  '3–20 friends • 1–3 imposters • Fully offline':
      '٣–٢٠ لاعباً • ١–٣ مخادعين • دون إنترنت',
  'Start game': 'ابدأ اللعبة',
  'HOW TO PLAY': 'طريقة اللعب',
  '1. Each player privately checks their card.\n2. Take turns giving a clue without saying the word.\n3. Discuss, then vote privately for a suspect.\n4. Catch every imposter to win. A tie means a revote.':
      '١. يرى كل لاعب بطاقته سراً.\n٢. يقدم كل لاعب تلميحاً دون ذكر الكلمة.\n٣. ناقشوا ثم صوتوا سراً للمشتبه به.\n٤. اكشفوا كل المخادعين للفوز. عند التعادل، أعيدوا التصويت.',
  'Gather your suspects': 'اجمع اللاعبين',
  'Add your friends, pick your packs, and pass the phone.':
      'أضف أصدقاءك، اختر الفئات، ثم مرر الهاتف.',
  'Enter a name': 'أدخل اسماً',
  'Use a different name': 'استخدم اسماً مختلفاً',
  'Choose at least one category.': 'اختر فئة واحدة على الأقل.',
  'Imposters': 'المخادعون',
  'Word packs': 'فئات الكلمات',
  'Discussion time': 'وقت النقاش',
  'Deal secret roles': 'وزع الأدوار السرية',
  'Hold to reveal': 'اضغط باستمرار للكشف',
  'Release to hide your card.': 'ارفع إصبعك لإخفاء البطاقة.',
  'You are the imposter': 'أنت المخادع',
  'Blend in. Listen to the clues. Bluff your way through.':
      'اندمج مع الآخرين. استمع للتلميحات وحاول الخداع.',
  'Remember the word. Give a clue, but do not say it.':
      'تذكر الكلمة. قدم تلميحاً دون ذكرها.',
  'Hide & pass': 'إخفاء وتمرير',
  'Start discussion': 'ابدأ النقاش',
  'Let the bluffing begin': 'لتبدأ الخدعة',
  'Time to vote!': 'حان وقت التصويت!',
  'Start private voting': 'ابدأ التصويت السري',
  'Submit private vote': 'تأكيد التصويت السري',
  'Too close to call': 'النتيجة متعادلة',
  'The vote is tied at the cutoff. Discuss again, then everyone votes again. Roles stay secret.':
      'تعادل التصويت عند الحد الفاصل. ناقشوا مجدداً ثم أعيدوا التصويت. تبقى الأدوار سرية.',
  'Vote again': 'صوتوا مجدداً',
  'Caught in the act!': 'تم كشف المخادعين!',
  'The bluff worked!': 'نجحت الخدعة!',
  'The group caught every imposter.': 'كشفت المجموعة كل المخادعين.',
  'At least one imposter escaped. Imposters win this round.':
      'نجا مخادع واحد على الأقل. فاز المخادعون بهذه الجولة.',
  'THE SECRET WORD': 'الكلمة السرية',
  'The votes': 'الأصوات',
  'Accused by the group': 'اتهمته المجموعة',
  'Not accused': 'لم يتم اتهامه',
  'Play again': 'العب مجدداً',
  'Change players & settings': 'تغيير اللاعبين والإعدادات',
  'End round': 'إنهاء الجولة',
  'End this round?': 'هل تريد إنهاء الجولة؟',
  'Your current round will be lost.': 'ستفقد الجولة الحالية.',
  'Keep playing': 'متابعة اللعب',
  'Settings': 'الإعدادات',
  'History & stats': 'السجل والإحصاءات',
  'Make it your party': 'خصص تجربتك',
  'Preferences are saved on this device.': 'تُحفظ التفضيلات على هذا الجهاز.',
  'Language': 'اللغة',
  'Appearance': 'المظهر',
  'System': 'حسب الجهاز',
  'Light': 'فاتح',
  'Dark': 'داكن',
  'Haptics': 'اهتزازات اللمس',
  'System click sounds': 'أصوات النقر',
  'Sound availability depends on device settings.':
      'يعتمد الصوت على إعدادات الجهاز.',
  'Your party story': 'سجل ألعابك',
  'Last 200 completed rounds on this device.':
      'آخر ٢٠٠ جولة مكتملة على هذا الجهاز.',
  'No rounds yet': 'لا توجد جولات بعد',
  'Finish a game to start your story.': 'أكمل لعبة لبدء سجلك.',
  'Player stats': 'إحصاءات اللاعبين',
  'Completed rounds': 'الجولات المكتملة',
  'Clear history': 'مسح السجل',
  'Clear all history?': 'هل تريد مسح السجل بالكامل؟',
  'This deletes saved rounds and player stats from this device.':
      'سيُحذف سجل الجولات وإحصاءات اللاعبين من هذا الجهاز.',
  'Cancel': 'إلغاء',
  'Clear': 'مسح',
  'Citizens won': 'فاز اللاعبون',
  'Imposters won': 'فاز المخادعون',
  'Storage is unavailable. Changes may not survive restarting the app.':
      'التخزين غير متاح. قد لا تُحفظ التغييرات بعد إعادة تشغيل التطبيق.',
  'Close': 'إغلاق',
  'Hold to reveal your secret card': 'اضغط باستمرار للكشف عن بطاقتك السرية',
  'Nature': 'الطبيعة',
  'Jobs': 'المهن',
  'Music': 'الموسيقى',
  'Home': 'المنزل',
  'Vehicles': 'المركبات',
  'Travel': 'السفر',
  'Food': 'الطعام',
  'Animals': 'الحيوانات',
  'Sports': 'الرياضة',
  'Technology': 'التقنية',
  'Places': 'الأماكن',
  'Objects': 'الأشياء',
};
