import 'package:flutter/material.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/domain/models/word_entry.dart';

/// Built-in words are translated; custom words are shown exactly as typed.
String wordLabel(BuildContext context, WordEntry word) =>
    word.custom ? word.value : translate(context, word.value);

String categoryLabel(BuildContext context, WordEntry word) =>
    word.custom ? word.category : translate(context, word.category);

class WordText extends StatelessWidget {
  const WordText(this.word, {super.key, this.style, this.textAlign});
  final WordEntry word;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) =>
      Text(wordLabel(context, word), style: style, textAlign: textAlign);
}
