import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, _CacheEntry> _memoryCache = {};

  /// Initialize the cache service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get cached data with automatic TTL expiration check
  T? get<T>(String key) {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!_isExpired(entry)) {
        return entry.data as T;
      } else {
        _memoryCache.remove(key);
      }
    }

    // Fall back to persistent storage
    if (_prefs == null) return null;
    
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final expiryTime = json['expiryTime'] as int?;
      
      if (expiryTime != null && DateTime.now().millisecondsSinceEpoch > expiryTime) {
        // Cache expired, remove it
        _prefs!.remove(key);
        return null;
      }

      return json['data'] as T;
    } catch (e) {
      // If parsing fails, remove corrupted cache
      _prefs!.remove(key);
      return null;
    }
  }

  /// Set cached data with TTL in minutes
  Future<void> set<T>(String key, T data, {int ttlMinutes = 10}) async {
    await init();
    
    // Store in memory cache for faster access
    final expiryTime = DateTime.now().add(Duration(minutes: ttlMinutes)).millisecondsSinceEpoch;
    _memoryCache[key] = _CacheEntry(data: data, expiryTime: expiryTime);

    // Store in persistent storage
    if (_prefs != null) {
      try {
        final json = jsonEncode({
          'data': data,
          'expiryTime': expiryTime,
        });
        await _prefs!.setString(key, json);
      } catch (e) {
        // If serialization fails, at least keep it in memory
        print('Failed to serialize cache for key $key: $e');
      }
    }
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    if (_prefs != null) {
      await _prefs!.remove(key);
    }
  }

  /// Clear all cache
  Future<void> clear() async {
    _memoryCache.clear();
    if (_prefs != null) {
      await _prefs!.clear();
    }
  }

  /// Clear cache by prefix pattern
  Future<void> clearByPrefix(String prefix) async {
    // Clear from memory cache
    _memoryCache.keys.where((key) => key.startsWith(prefix)).toList()
      .forEach((key) => _memoryCache.remove(key));

    // Clear from persistent storage
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith(prefix)) {
          await _prefs!.remove(key);
        }
      }
    }
  }

  /// Check if cache entry is expired
  bool _isExpired(_CacheEntry entry) {
    return DateTime.now().millisecondsSinceEpoch > entry.expiryTime;
  }

  /// Get cache size (for monitoring)
  int get cacheSize => _memoryCache.length;
}

class _CacheEntry {
  final dynamic data;
  final int expiryTime;

  _CacheEntry({required this.data, required this.expiryTime});
}
