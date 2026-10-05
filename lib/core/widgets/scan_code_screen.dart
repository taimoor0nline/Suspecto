import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:suspecto/core/localization.dart';

/// Scans QR codes until [parse] accepts one, then pops with the result.
/// Used for multi-phone join codes and shared word packs.
class ScanCodeScreen<T extends Object> extends StatefulWidget {
  const ScanCodeScreen({super.key, required this.parse, required this.hint});

  /// Returns the scanned value, or null to keep scanning.
  final T? Function(String text) parse;

  /// English instruction shown over the camera.
  final String hint;

  @override
  State<ScanCodeScreen<T>> createState() => _ScanCodeScreenState<T>();
}

class _ScanCodeScreenState<T extends Object> extends State<ScanCodeScreen<T>> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) {
      return;
    }
    for (final barcode in capture.barcodes) {
      final value = widget.parse(barcode.rawValue ?? '');
      if (value != null) {
        _done = true;
        Navigator.pop(context, value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const LocalText('Scan QR code')),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: LocalText(
                    'Camera unavailable.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.black54,
                child: SafeArea(
                  top: false,
                  child: LocalText(
                    widget.hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
