import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GeminiCacheManager {
  static const String _contextKey = 'gemini_context_v1';
  static const String _cacheEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/cachedContents';

  // Current ephemeral ID of the cache on Gemini Server
  String? _remoteCacheName;
  DateTime? _cacheExpiration;

  /// Add a new event to the local context log
  Future<void> logEvent({
    required String type, // 'workout', 'nutrition', 'chat', 'biometrics'
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentJson = prefs.getString(_contextKey);

    Map<String, dynamic> context = {};
    if (currentJson != null) {
      context = json.decode(currentJson);
    }

    // Initialize list if needed
    if (!context.containsKey('history')) {
      context['history'] = [];
    }

    final List<dynamic> history = context['history'];

    // Add new event
    history.add({
      'timestamp': DateTime.now().toIso8601String(),
      'type': type,
      'data': data,
    });

    // Keep only last 50 events (Rolling Window)
    if (history.length > 50) {
      history.removeAt(0);
    }

    context['history'] = history;

    await prefs.setString(_contextKey, json.encode(context));
    debugPrint('Logged event: $type');
  }

  /// Get the full formatted context for Gemini
  Future<String> getFormattedContext() async {
    final prefs = await SharedPreferences.getInstance();
    final currentJson = prefs.getString(_contextKey);
    if (currentJson == null) return "User is a new user with no history.";

    final context = json.decode(currentJson);
    final history = context['history'] as List<dynamic>;

    StringBuffer buffer = StringBuffer();
    buffer.writeln("USER HISTORY LOG:");

    for (var event in history) {
      final date = DateTime.parse(event['timestamp']).toLocal();
      buffer.writeln(
        "[$date] [${event['type']}]: ${json.encode(event['data'])}",
      );
    }

    return buffer.toString();
  }

  /// Get raw logs for UI display
  Future<List<Map<String, dynamic>>> getRawLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final currentJson = prefs.getString(_contextKey);
    if (currentJson == null) return [];

    final context = json.decode(currentJson);
    return List<Map<String, dynamic>>.from(context['history']);
  }

  /// Sync local context to Gemini Cloud Cache
  /// Returns the `cachedContent` resource name (e.g., `cachedContents/12345`)
  Future<String?> syncCache(String apiKey, String systemInstruction) async {
    try {
      // 1. If we have a valid cache, just return it (or refresh TTL - TODO)
      if (_remoteCacheName != null &&
          _cacheExpiration != null &&
          _cacheExpiration!.isAfter(
            DateTime.now().add(const Duration(minutes: 5)),
          )) {
        return _remoteCacheName;
      }

      // 2. Build the Content
      final userHistory = await getFormattedContext();
      final fullSystemPrompt =
          """
$systemInstruction

CONTEXTUAL MEMORY:
$userHistory
""";

      // 3. Create new Cache
      final uri = Uri.parse('$_cacheEndpoint?key=$apiKey');

      final body = json.encode({
        'model':
            'models/gemini-1.5-flash-001', // Using 1.5 Flash for cache efficiency
        'contents': [
          {
            'parts': [
              {'text': fullSystemPrompt},
            ],
            'role':
                'user', // System instructions often cached as user/system role depending on API version
          },
        ],
        'ttl': '300s', // 5 minutes TTL for testing, increase for prod
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        _remoteCacheName = data['name'];
        // Parse expiration
        if (data['expireTime'] != null) {
          _cacheExpiration = DateTime.parse(data['expireTime']);
        } else {
          // Fallback
          _cacheExpiration = DateTime.now().add(const Duration(minutes: 5));
        }

        debugPrint(
          'Cache Created: $_remoteCacheName, Expires: $_cacheExpiration',
        );
        return _remoteCacheName;
      } else {
        debugPrint(
          'Failed to create cache: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Cache Sync Error: $e');
      return null;
    }
  }
  // --- Smart Caching (Hackathon Feature) ---

  static const String _historyKey = 'gemini_history_v2';
  static const String _cacheInfoKey = 'gemini_active_cache_info';
  static const int _cachingThresholdChars = 10000;

  /// 1. Log chat interaction locally (Append Only)
  Future<void> logInteraction(String role, String text) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];

    final entry = json.encode({
      'role': role,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    });

    history.add(entry);
    // Keep last 50 only
    if (history.length > 50) history.removeAt(0);

    await prefs.setStringList(_historyKey, history);
  }

  /// 2. Get formatted history for Gemini API
  Future<List<Map<String, dynamic>>> _getHistoryContent() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_historyKey) ?? [];

    return rawList.map((e) {
      final map = json.decode(e) as Map<String, dynamic>;
      return {
        'role': map['role'],
        'parts': [
          {'text': map['text']},
        ],
      };
    }).toList();
  }

  /// 3. Smart Cache Sync
  /// Returns cache name if cached, null if standard transmission should be used.
  Future<String?> getOrSyncCache({
    required String apiKey,
    required String systemInstruction,
    required String modelName,
  }) async {
    final history = await _getHistoryContent();
    if (history.isEmpty) return null;

    final fullText = history.fold(
      '',
      (String p, e) => p + ((e['parts'] as List)[0]['text'] as String),
    );

    // A. Check threshold
    if (fullText.length < _cachingThresholdChars) {
      debugPrint('Skipping cache: Data too small (${fullText.length} chars)');
      return null;
    }

    final prefs = await SharedPreferences.getInstance();

    // B. Check existing valid cache
    String? cachedName = prefs.getString(_cacheInfoKey);
    if (cachedName != null) {
      // In prod, check TTL here or via API
      debugPrint('Using existing cache: $cachedName');
      return cachedName;
    }

    // C. Create new Cache
    try {
      final uri = Uri.parse('$_cacheEndpoint?key=$apiKey');
      final body = json.encode({
        'model': modelName,
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
        'contents': history,
        'ttl': '600s', // 10 mins for demo
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final newCacheName = data['name'];
        await prefs.setString(_cacheInfoKey, newCacheName);
        debugPrint('New Cache Created: $newCacheName');
        return newCacheName;
      } else {
        debugPrint('Cache Creation Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Cache Sync Exception: $e');
      return null;
    }
  }
}
