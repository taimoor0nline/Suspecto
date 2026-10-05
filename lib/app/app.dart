import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:suspecto/app/theme/app_theme.dart';
import 'package:suspecto/core/app_store.dart';
import 'package:suspecto/core/localization.dart';
import 'package:suspecto/features/game/presentation/game_page.dart';
import 'package:suspecto/features/home/presentation/home_screen.dart';
import 'package:suspecto/features/lan/data/lan_transport.dart';
import 'package:suspecto/features/lan/domain/join_code.dart';
import 'package:suspecto/features/lan/domain/join_link.dart';
import 'package:suspecto/features/lan/domain/room_code.dart';
import 'package:suspecto/features/lan/presentation/join_screen.dart';

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
                locale: _store.languageConfig.resolve(_store.language).locale,
                supportedLocales: _store.languageConfig.enabled
                    .map((language) => language.locale)
                    .toList(),
                builder: (context, child) => Directionality(
                  textDirection:
                      _store.languageConfig.resolve(_store.language).direction,
                  child: child!,
                ),
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate
                ],
                home: const HomeScreen(),
                onGenerateRoute: _joinRoute,
                onUnknownRoute: (_) => MaterialPageRoute<void>(
                  builder: (context) => GamePage(
                    title: "This link didn't work",
                    subtitle:
                        'Ask the host for the code and join by typing it.',
                    children: [
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const LocalText('Back'),
                      ),
                    ],
                  ),
                ),
              )));
}

/// Opens the join screen for a join link (see [JoinLink]). Returns null for
/// other routes, and for links this build cannot join.
Route<void>? _joinRoute(RouteSettings settings) {
  final code = JoinLink.parse(settings.name ?? '');
  final Widget? screen = switch (code) {
    final RoomCode room when onlineRoomsAvailable =>
      JoinScreen(online: true, initialCode: room.code),
    final JoinCode wifi when lanSupported => JoinScreen(initialCode: wifi.code),
    _ => null,
  };
  return screen == null
      ? null
      : MaterialPageRoute<void>(builder: (_) => screen, settings: settings);
}
