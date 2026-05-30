import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocationDictionaryService {
  static const _key = 'learned_locations';

  Future<Map<String, bool>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return {};
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as bool));
  }

  Future<bool?> lookup(String location) async {
    final dict = await getAll();
    final normalized = location.toLowerCase().trim();
    return dict[normalized];
  }

  Future<void> save(String location, bool requiresTravel) async {
    final dict = await getAll();
    dict[location.toLowerCase().trim()] = requiresTravel;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(dict));
  }

  Future<void> remove(String location) async {
    final dict = await getAll();
    dict.remove(location.toLowerCase().trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(dict));
  }
}
