import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/body_progress_entry.dart';

class BodyProgressStorage {
  static const String _entriesKey = 'xafit_body_progress_entries';

  static Future<List<BodyProgressEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_entriesKey);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List;

    final entries = decoded
        .map(
          (item) => BodyProgressEntry.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static Future<void> saveEntry(BodyProgressEntry entry) async {
    final entries = await loadEntries();
    entries.add(entry);
    entries.sort((a, b) => b.date.compareTo(a.date));

    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toMap()).toList());

    await prefs.setString(_entriesKey, raw);
  }

  static Future<void> clearAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entriesKey);
  }
}
