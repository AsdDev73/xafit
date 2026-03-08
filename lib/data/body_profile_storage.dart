import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/body_profile.dart';

class BodyProfileStorage {
  static const String _profileKey = 'xafit_body_profile';

  static Future<BodyProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);

    if (raw == null || raw.isEmpty) {
      return BodyProfile.empty;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return BodyProfile.fromMap(decoded);
  }

  static Future<void> saveProfile(BodyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(profile.toMap());
    await prefs.setString(_profileKey, raw);
  }
}
