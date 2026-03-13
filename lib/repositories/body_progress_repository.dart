import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/body_progress_entry.dart';

abstract class BodyProgressRepository {
  Future<List<BodyProgressEntry>> getEntries();
  Future<void> saveEntry(BodyProgressEntry entry);
  Future<void> deleteEntry(String entryId);
  Future<void> clearAllEntries();
}

class SharedPrefsBodyProgressRepository implements BodyProgressRepository {
  static const String _entriesKey = 'xafit_body_progress_entries';

  @override
  Future<List<BodyProgressEntry>> getEntries() async {
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

  @override
  Future<void> saveEntry(BodyProgressEntry entry) async {
    final entries = await getEntries();

    final index = entries.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }

    entries.sort((a, b) => b.date.compareTo(a.date));

    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toMap()).toList());
    await prefs.setString(_entriesKey, raw);
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    final entries = await getEntries();
    entries.removeWhere((item) => item.id == entryId);

    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toMap()).toList());
    await prefs.setString(_entriesKey, raw);
  }

  @override
  Future<void> clearAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entriesKey);
  }
}
