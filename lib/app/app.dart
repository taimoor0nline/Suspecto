import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:suspecto/app/theme/app_theme.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/features/home/presentation/home_screen.dart';

class SuspectoApp extends StatefulWidget {
  const SuspectoApp({super.key, this.store});
  final AppStore? store;
  @override
  State<SuspectoApp> createState() => _SuspectoAppState();
}

class _SuspectoAppState extends State<SuspectoApp> {
  late final AppStore _store = widget.store ?? AppStore();
  @override
  void dispose() {
    if (widget.store == null) {
      _store.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StoreScope(
      store: _store,
      child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) => MaterialApp(
                title: 'Suspecto',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: _store.themeMode,
                locale: Locale(_store.language),
                supportedLocales: const [Locale('en'), Locale('ar')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate
                ],
                home: const HomeScreen(),
              )));
}
