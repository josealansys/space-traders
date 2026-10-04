import 'dart:convert';
import 'package:flutter/services.dart';

/// Loads game data from JSON assets.
class DataLoader {
  static Map<String, dynamic>? _commoditiesCache;
  static Map<String, dynamic>? _planetsCache;
  static Map<String, dynamic>? _shipsCache;

  /// Load commodities config from assets.
  static Future<List<Map<String, dynamic>>> loadCommodities() async {
    if (_commoditiesCache != null) {
      return List<Map<String, dynamic>>.from(_commoditiesCache!['commodities']);
    }
    final raw = await rootBundle.loadString('assets/data/commodities.json');
    _commoditiesCache = json.decode(raw) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(_commoditiesCache!['commodities']);
  }

  /// Load planets config from assets.
  static Future<List<Map<String, dynamic>>> loadPlanets() async {
    if (_planetsCache != null) {
      return List<Map<String, dynamic>>.from(_planetsCache!['planets']);
    }
    final raw = await rootBundle.loadString('assets/data/planets.json');
    _planetsCache = json.decode(raw) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(_planetsCache!['planets']);
  }

  /// Load ships config from assets.
  static Future<List<Map<String, dynamic>>> loadShips() async {
    if (_shipsCache != null) {
      return List<Map<String, dynamic>>.from(_shipsCache!['ships']);
    }
    final raw = await rootBundle.loadString('assets/data/ships.json');
    _shipsCache = json.decode(raw) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(_shipsCache!['ships']);
  }

  /// Clear all caches (useful for testing or hot reload).
  static void clearCache() {
    _commoditiesCache = null;
    _planetsCache = null;
    _shipsCache = null;
  }
}
