import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/body_profile.dart';

abstract class BodyProfileRepository {
  Future<BodyProfile> getProfile();
  Future<void> saveProfile(BodyProfile profile);
}

class SharedPrefsBodyProfileRepository implements BodyProfileRepository {
  static const String _profileKey = 'xafit_body_profile';

  @override
  Future<BodyProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);

    if (raw == null || raw.isEmpty) {
      return BodyProfile.empty;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return BodyProfile.fromMap(decoded);
  }

  @override
  Future<void> saveProfile(BodyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(profile.toMap());
    await prefs.setString(_profileKey, raw);
  }
}
