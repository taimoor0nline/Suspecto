import 'package:flutter/material.dart';
import 'package:suspecto/app/app.dart';
import 'package:suspecto/core/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(SuspectoApp(store: store));
}
