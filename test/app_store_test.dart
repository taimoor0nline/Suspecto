import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suspecto/core/app_store.dart';

void main() {
  test('malformed records and setup do not discard valid history', () async {
    final valid = {'id': 'r1', 'word': 'Pizza', 'category': 'Food', 'date': '2026-10-04T10:00:00Z', 'players': ['Ali', 'Sara', 'Omar'], 'imposters': ['Sara'], 'accused': ['Sara'], 'citizensWin': true};
    final invalid = {...valid, 'id': 'bad', 'players': ['Ali', '', 'Omar']};
    SharedPreferences.setMockInitialValues({'suspecto.v1': jsonEncode({'language': 'ar', 'players': 42, 'categories': ['Food', 42], 'history': [valid, 42, invalid, {...valid, 'id': 'r2'}]})});
    final store = AppStore();
    await store.load();
    expect(store.language, 'ar');
    expect(store.lastPlayers, isEmpty);
    expect(store.history.map((r) => r['id']), ['r1', 'r2']);
    expect(store.stats.keys, ['Ali', 'Sara', 'Omar']);
  });
  test('settings and completed rounds survive reload without duplicates', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await store.load();
    await store.updateSettings(language: 'ar', haptics: false);
    await store.recordRound(id: 'r1', word: 'Pizza', category: 'Food', players: ['Ali', 'Sara', 'Omar'], imposters: ['Sara'], accused: ['Sara'], citizensWin: true);
    await store.recordRound(id: 'r1', word: 'Pizza', category: 'Food', players: ['Ali', 'Sara', 'Omar'], imposters: ['Sara'], accused: ['Sara'], citizensWin: true);
    final reloaded = AppStore();
    await reloaded.load();
    expect(reloaded.language, 'ar');
    expect(reloaded.haptics, false);
    expect(reloaded.history, hasLength(1));
    expect(reloaded.stats['Ali']!.wins, 1);
    expect(reloaded.stats['Sara']!.wins, 0);
    await reloaded.clearHistory();
    expect(reloaded.history, isEmpty);
  });
  test('corrupt saved data falls back to safe defaults', () async {
    SharedPreferences.setMockInitialValues({'suspecto.v1': 'broken'});
    final store = AppStore();
    await store.load();
    expect(store.language, 'en');
    expect(store.history, isEmpty);
  });
}
