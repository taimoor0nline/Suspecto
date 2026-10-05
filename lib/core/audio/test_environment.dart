// Detects `flutter test`, where audio plugins are unavailable.
export 'package:suspecto/core/audio/test_environment_stub.dart'
    if (dart.library.io) 'package:suspecto/core/audio/test_environment_io.dart';
