import 'package:shared_preferences/shared_preferences.dart';

class FavoriteExercisesService {
  static const String _favoriteIdsKey = 'xafit_favorite_exercise_ids';

  const FavoriteExercisesService();

  Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_favoriteIdsKey) ?? <String>[];
    return ids.toSet();
  }

  Future<bool> isFavorite(String exerciseId) async {
    final favoriteIds = await getFavoriteIds();
    return favoriteIds.contains(exerciseId);
  }

  Future<bool> toggleFavorite(String exerciseId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds =
        prefs.getStringList(_favoriteIdsKey)?.toSet() ?? <String>{};

    late final bool isNowFavorite;
    if (favoriteIds.contains(exerciseId)) {
      favoriteIds.remove(exerciseId);
      isNowFavorite = false;
    } else {
      favoriteIds.add(exerciseId);
      isNowFavorite = true;
    }

    final sorted = favoriteIds.toList()..sort();
    await prefs.setStringList(_favoriteIdsKey, sorted);
    return isNowFavorite;
  }

  Future<void> setFavorite(String exerciseId, bool isFavorite) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds =
        prefs.getStringList(_favoriteIdsKey)?.toSet() ?? <String>{};

    if (isFavorite) {
      favoriteIds.add(exerciseId);
    } else {
      favoriteIds.remove(exerciseId);
    }

    final sorted = favoriteIds.toList()..sort();
    await prefs.setStringList(_favoriteIdsKey, sorted);
  }

  Future<void> clearAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoriteIdsKey);
  }
}
