import 'package:suspecto/features/game/data/local/question_pairs.dart';
import 'package:suspecto/features/game/data/local/word_translations.dart';
import 'package:flutter/material.dart';
import 'package:suspecto/core/ui_translations.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/l10n/arabic_strings.dart';

String translate(BuildContext context, String text) {
  final store = StoreScope.maybeOf(context);
  final language =
      store == null ? 'en' : store.languageConfig.resolve(store.language).code;
  return translateForLanguage(language, text);
}

String translateForLanguage(String language, String text) {
  if (language == 'en') return text;
  final words = wordTranslations[language];
  if (words != null && words.containsKey(text)) return words[text]!;
  final questions = questionTranslations[language];
  if (questions != null && questions.containsKey(text)) {
    return questions[text]!;
  }
  if (language != 'ar') {
    final strings = uiTranslations[language];
    if (strings == null) return text;
    if (strings.containsKey(text)) return strings[text]!;
    for (final (pattern, template, parameters) in _dynamicMessages) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final translatedTemplate = strings[template];
      if (translatedTemplate == null) return text;
      var result = translatedTemplate;
      for (var i = 0; i < parameters.length; i++) {
        result = result.replaceAll('{${parameters[i]}}', match[i + 1]!);
      }
      return result;
    }
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
    (RegExp(r'^Players \((\d+)/20\)$'), (m) => 'اللاعبون (${m[1]}/20)'),
    (RegExp(r'^(\d+) of (\d+) ready$'), (m) => '${m[1]} من ${m[2]} جاهزون'),
    (
      RegExp(
          r'^(.+) answers first\. Everyone answers their question out loud, then discuss whose answer did not fit\.$'),
      (m) =>
          'يجيب ${m[1]} أولاً. يجيب الجميع عن أسئلتهم بصوت عالٍ، ثم ناقشوا من كانت إجابته غريبة.'
    ),
    (RegExp(r'^Jester: (.+)$'), (m) => 'المهرّج: ${m[1]}'),
    (RegExp(r'^(\d+) imposter wins$'), (m) => '${m[1]} انتصارات كمخادع'),
    (RegExp(r'^(\d+) imposters spotted$'), (m) => 'كشف ${m[1]} مخادعين'),
    (RegExp(r'^(\d+) votes received$'), (m) => 'تلقى ${m[1]} أصوات'),
    (RegExp(r'^(\d+) Jester wins$'), (m) => '${m[1]} انتصارات كمهرّج'),
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

final _dynamicMessages = <(RegExp, String, List<String>)>[
  (RegExp(r'^Pass to (.+)$'), 'Pass to {name}', ['name']),
  (RegExp(r'^I am (.+)$'), 'I am {name}', ['name']),
  (RegExp(r'^Player (\d+)$'), 'Player {number}', ['number']),
  (RegExp(r'^Remove player (\d+)$'), 'Remove player {number}', ['number']),
  (
    RegExp(r'^Add player \((\d+)/20\)$'),
    'Add player ({number}/20)',
    ['number']
  ),
  (RegExp(r'^(\d+) min$'), '{number} min', ['number']),
  (RegExp(r'^(\d+) votes$'), '{number} votes', ['number']),
  (
    RegExp(r'^Card (\d+) of (\d+)\. Everyone else, look away\.$'),
    'Card {number} of {total}. Everyone else, look away.',
    ['number', 'total']
  ),
  (
    RegExp(r'^Vote (\d+) of (\d+)\. Choose your suspect privately\.$'),
    'Vote {number} of {total}. Choose your suspect privately.',
    ['number', 'total']
  ),
  (
    RegExp(
        r'^(.+) starts\. Give one clue each, then discuss who is bluffing\. Keep the word secret\.$'),
    '{name} starts. Give one clue each, then discuss who is bluffing. Keep the word secret.',
    ['name']
  ),
  (RegExp(r'^Imposters: (.+)$'), 'Imposters: {name}', ['name']),
  (
    RegExp(r'^Caught: (.+)\. Guess the secret word to steal the win\.$'),
    'Caught: {name}. Guess the secret word to steal the win.',
    ['name']
  ),
  (RegExp(r'^(\d+) pts$'), '{number} pts', ['number']),
  (RegExp(r'^\+(\d+) this round$'), '+{number} this round', ['number']),
  (RegExp(r'^(.+): \+(\d+) pts$'), '{name}: +{number} pts', ['name', 'number']),
  (RegExp(r'^(\d+) words$'), '{number} words', ['number']),
  (RegExp(r'^Players \((\d+)/20\)$'), 'Players ({number}/20)', ['number']),
  (
    RegExp(r'^(\d+) of (\d+) ready$'),
    '{number} of {total} ready',
    ['number', 'total']
  ),
  (
    RegExp(r'^(\d+) rounds • (\d+) wins • (\d+) imposter roles$'),
    '{number} rounds • {wins} wins • {total} imposter roles',
    ['number', 'wins', 'total']
  ),
  (
    RegExp(
        r'^(.+) answers first\. Everyone answers their question out loud, then discuss whose answer did not fit\.$'),
    '{name} answers first. Everyone answers their question out loud, then discuss whose answer did not fit.',
    ['name']
  ),
  (RegExp(r'^Jester: (.+)$'), 'Jester: {name}', ['name']),
  (RegExp(r'^(\d+) imposter wins$'), '{number} imposter wins', ['number']),
  (
    RegExp(r'^(\d+) imposters spotted$'),
    '{number} imposters spotted',
    ['number']
  ),
  (RegExp(r'^(\d+) votes received$'), '{number} votes received', ['number']),
  (RegExp(r'^(\d+) Jester wins$'), '{number} Jester wins', ['number']),
];

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
