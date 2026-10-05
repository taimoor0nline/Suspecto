import 'package:suspecto/features/game/data/local/word_translations.dart';
import 'package:flutter/material.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/l10n/arabic_strings.dart';

String translate(BuildContext context, String text) {
  final store = StoreScope.maybeOf(context);
  final language =
      store == null ? 'en' : store.languageConfig.resolve(store.language).code;
  if (language != 'ar') {
    return text;
  }
  if (arabicWords.containsKey(text)) {
    return arabicWords[text]!;
  }
  if (arabicStrings.containsKey(text)) {
    return arabicStrings[text]!;
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
    (
      RegExp(r'^Caught: (.+)\. Guess the secret word to steal the win\.$'),
      (m) => 'تم كشف: ${m[1]}. خمّنوا الكلمة السرية لخطف الفوز.'
    ),
    (RegExp(r'^(\d+) pts$'), (m) => '${m[1]} نقطة'),
    (RegExp(r'^\+(\d+) this round$'), (m) => '+${m[1]} في هذه الجولة'),
    (RegExp(r'^(.+): \+(\d+) pts$'), (m) => '${m[1]}: +${m[2]} نقطة'),
    (RegExp(r'^(\d+) words$'), (m) => '${m[1]} كلمة'),
    (
      RegExp(r'^(\d+) rounds • (\d+) wins • (\d+) imposter roles$'),
      (m) => '${m[1]} جولات • ${m[2]} فوز • ${m[3]} أدوار مخادع'
    ),
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
