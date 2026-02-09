import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../services/gemini_cache_manager.dart';
import '../../data/datasources/gemini_remote_datasource_impl.dart';
import '../../data/datasources/gemini_remote_datasource.dart';
// Note: You'll need to inject the specific implementation or use GetIt

import 'package:flutter_dotenv/flutter_dotenv.dart';

class LifeLogController extends ChangeNotifier {
  final GeminiCacheManager _cacheManager = GeminiCacheManager();
  final GeminiRemoteDataSource _geminiDataSource = GeminiRemoteDataSourceImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> get logs => _logs;

  Future<void> loadLogs() async {
    _logs = await _cacheManager.getRawLogs();
    // Sort by timestamp desc
    _logs.sort(
      (a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String),
    );
    notifyListeners();
  }

  Future<void> addTextLog(String text) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _cacheManager.logEvent(
        type: 'chat',
        data: {'message': text, 'role': 'user'},
      );
      await loadLogs();

      // Get AI Response
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey != null) {
        final response = await _geminiDataSource.generateContent(
          apiKey: apiKey,
          systemInstruction:
              "You are a helpful holistic fitness coach. Use the context history to answer user questions about their progress, nutrition, and workouts. Be encouraging and specific.",
          prompt: text,
        );

        if (response != null) {
          await _cacheManager.logEvent(
            type: 'chat',
            data: {'message': response, 'role': 'model'},
          );
          await loadLogs();
        }
      }
    } catch (e) {
      debugPrint('Error logging text: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addImageLog(File image, String prompt) async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) throw Exception('API Key not found');

      final analysis = await _geminiDataSource.analyzeImage(
        apiKey: apiKey,
        prompt: '$prompt. Concise, nutritional focus.',
        image: image,
      );

      await _cacheManager.logEvent(
        type: 'nutrition',
        data: {'analysis': analysis ?? 'No analysis', 'image_path': image.path},
      );
      await loadLogs();
    } catch (e) {
      debugPrint('Error logging image: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
