import 'dart:io';

bool get runningInFlutterTest =>
    Platform.environment.containsKey('FLUTTER_TEST');
