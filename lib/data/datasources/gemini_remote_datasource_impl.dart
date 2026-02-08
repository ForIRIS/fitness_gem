import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'gemini_remote_datasource.dart';

class GeminiRemoteDataSourceImpl implements GeminiRemoteDataSource {
  static const String _uploadUrl =
      'https://generativelanguage.googleapis.com/upload/v1beta/files';
  static const String _generateUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  @override
  ChatSession startChat({
    required String apiKey,
    required String systemInstruction,
    String model = 'gemini-3-flash-preview',
  }) {
    final generativeModel = GenerativeModel(
      model: model,
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstruction),
    );
    return generativeModel.startChat();
  }

  @override
  Future<String?> sendMessage({
    required ChatSession chatSession,
    required String message,
  }) async {
    final response = await chatSession.sendMessage(Content.text(message));
    return response.text;
  }

  @override
  Future<String?> generateContent({
    required String apiKey,
    required String systemInstruction,
    required String prompt,
    String model = 'gemini-3-flash-preview',
    String? responseMimeType,
  }) async {
    try {
      final generativeModel = GenerativeModel(
        model: model,
        apiKey: apiKey,
        systemInstruction: Content.system(systemInstruction),
        generationConfig: responseMimeType != null
            ? GenerationConfig(responseMimeType: responseMimeType)
            : null,
      );

      final response = await generativeModel.generateContent([
        Content.text(prompt),
      ]);
      return response.text;
    } catch (e) {
      debugPrint('Gemini generateContent error: $e');
      throw Exception('Failed to generate content: $e');
    }
  }

  @override
  Future<String?> uploadFile({
    required String apiKey,
    required File file,
  }) async {
    try {
      final uri = Uri.parse('$_uploadUrl?key=$apiKey');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      request.fields['file'] = json.encode({
        'display_name': 'upload_${DateTime.now().millisecondsSinceEpoch}',
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBody);
        return jsonData['file']['uri'];
      } else {
        debugPrint('Upload failed: $responseBody');
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> waitForFileActive({
    required String apiKey,
    required String fileUri,
  }) async {
    // Extract file name from URI
    // URI format: https://generativelanguage.googleapis.com/v1beta/files/NAME
    final fileName = fileUri.split('/files/').last;
    final name = 'files/$fileName';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/$name?key=$apiKey',
    );

    int attempts = 0;
    while (attempts < 30) {
      try {
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final state = data['state'];
          debugPrint('File $name state: $state');
          if (state == 'ACTIVE') {
            return true;
          } else if (state == 'FAILED') {
            return false;
          }
        }
      } catch (e) {
        debugPrint('Error checking file state: $e');
      }
      await Future.delayed(const Duration(seconds: 2));
      attempts++;
    }
    return false;
  }

  @override
  Future<Map<String, dynamic>?> analyzeInterSet({
    required String apiKey,
    required String systemInstruction,
    required Map<String, dynamic> inputContext,
    required String rgbUri,
    required String controlNetUri,
    String mimeType = 'video/mp4',
    String model = 'gemini-3-flash-preview',
  }) async {
    try {
      final contentParts = [
        {'text': json.encode(inputContext)},
        {
          'file_data': {'mime_type': mimeType, 'file_uri': rgbUri},
        },
        {
          'file_data': {'mime_type': 'video/mp4', 'file_uri': controlNetUri},
        },
      ];

      return await _postMultimodal(
        apiKey: apiKey,
        systemInstruction: systemInstruction,
        contentParts: contentParts,
        model: model,
      );
    } catch (e) {
      debugPrint('Analyst Error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> analyzeBaseline({
    required String apiKey,
    required String systemInstruction,
    required String prompt,
    required String videoUri,
    String model = 'gemini-3-flash-preview',
  }) async {
    try {
      final contentParts = [
        {'text': prompt},
        {
          'file_data': {'mime_type': 'video/mp4', 'file_uri': videoUri},
        },
      ];

      return await _postMultimodal(
        apiKey: apiKey,
        systemInstruction: systemInstruction,
        contentParts: contentParts,
        model: model,
      );
    } catch (e) {
      debugPrint('Baseline Analyst Error: $e');
      rethrow;
    }
  }

  /// Helper for Gemini 3 Multimodal API calls
  Future<Map<String, dynamic>?> _postMultimodal({
    required String apiKey,
    required String systemInstruction,
    required List<Map<String, dynamic>> contentParts,
    String model = 'gemini-3-flash-preview',
    double temperature = 0.2,
  }) async {
    final endpoint = model == 'gemini-3-flash-preview'
        ? _generateUrl
        : 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

    final uri = Uri.parse('$endpoint?key=$apiKey');

    final body = json.encode({
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': [
        {'parts': contentParts},
      ],
      'generationConfig': {
        'temperature': temperature,
        'responseMimeType': 'application/json',
      },
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final content = candidates[0]['content'];
      if (content == null) return null;

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      final text = parts[0]['text'];
      if (text == null) return null;

      // Robust JSON extraction in case there are markdown markers
      String cleanText = (text as String).trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }

      try {
        return json.decode(cleanText.trim());
      } catch (e) {
        debugPrint(
          'JSON decode error in Gemini response: $e\nOriginal text: $text',
        );
        return null;
      }
    } else {
      debugPrint(
        'Gemini Multimodal failed: ${response.statusCode} - ${response.body}',
      );
      throw Exception(
        'Gemini Multimodal failed with status ${response.statusCode}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> generatePostWorkoutSummary({
    required String apiKey,
    required String systemInstruction,
    required String userLanguage,
    required String exerciseName,
    required int initialStability,
    required int initialMobility,
    required int sessionStability,
    required int totalReps,
    String? primaryFaultDetected,
  }) async {
    try {
      // Build the input context as specified in the prompt
      final inputContext = {
        'user_language': userLanguage,
        'exercise_name': exerciseName,
        'baseline_metrics': {
          'initial_stability': initialStability,
          'initial_mobility': initialMobility,
        },
        'current_session_metrics': {
          'session_stability': sessionStability,
          'total_reps': totalReps,
          if (primaryFaultDetected != null)
            'primary_fault_detected': primaryFaultDetected,
        },
      };

      final contentParts = [
        {'text': json.encode(inputContext)},
      ];

      return await _postMultimodal(
        apiKey: apiKey,
        systemInstruction: systemInstruction,
        contentParts: contentParts,
        temperature: 0.4, // Slightly higher for more creative narrative
      );
    } catch (e) {
      debugPrint('Storyteller Error: $e');
      rethrow;
    }
  }
}
