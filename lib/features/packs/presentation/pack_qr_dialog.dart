import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/packs/domain/pack_code.dart';
import 'package:suspecto/features/packs/domain/word_pack.dart';

/// Shows [pack] as a QR code another phone can scan from Word packs.
Future<void> showPackQr(BuildContext context, WordPack pack) {
  final code = PackCode.encode(pack);
  if (code == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: LocalText(
            'This pack is too big for one QR code. Try fewer or shorter words.')));
    return Future.value();
  }
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(pack.name, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox.square(
              dimension: 240,
              child: QrImageView(
                data: code,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
                semanticsLabel: translate(context, 'Word pack QR code'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LocalText(wordsText(pack.entries.length)),
          const SizedBox(height: 8),
          const LocalText(
            'On the other phone: Word packs → Scan a pack.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const LocalText('Close'),
        ),
      ],
    ),
  );
}
