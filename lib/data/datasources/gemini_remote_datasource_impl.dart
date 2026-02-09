import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'gemini_remote_datasource.dart';
import '../../services/gemini_cache_manager.dart';

class GeminiRemoteDataSourceImpl implements GeminiRemoteDataSource {
  static const String _uploadUrl =
      'https://generativelanguage.googleapis.com/upload/v1beta/files';
  static const String _generateUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  final GeminiCacheManager _cacheManager = GeminiCacheManager();

  @override
  ChatSession startChat({
    required String apiKey,
    required String systemInstruction,
    String model = 'gemini-3-flash-preview',
  }) {
    // We cannot easily make startChat async to fetch cache in the interface
    // So for chat, we might rely on the first message or use a sync cache if possible.
    // However, GenerativeModel.startChat is synchronous.
    // Workaround: We will rely on the UI/Controller to pass the *augmented* system instruction
    // OR we just init the model with the base instruction and let the history be passed in prompts.

    // For now, we will just use the provided instruction,
    // but we can assume the caller has already appended history if needed.
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
    File? image, // Added image parameter
  }) async {
    try {
      final parts = <Part>[TextPart(message)];

      if (image != null) {
        // We typically need to upload the file for Gemini API (File API) or use inline data.
        // For ChatSession in google_generative_ai package, it supports DataPart which is inline bytes for small images,
        // or FileData for uploaded files.
        // Since this is likely a small food image, let's try DataPart (inline) first for simplicity if it adheres to size limits,
        // BUT `google_generative_ai` recommends File API for most things.
        // However, `ChatSession.sendMessage` takes `Content`.
        // If we use `uploadFile` method we implemented, it returns a URI.
        // The `google_generative_ai` package `FileData` constructor takes `uri`.

        // Let's use our existing uploadFile logic to get a URI, but we need the API key here.
        // The `startChat` didn't save the API key in the session object directly accessible here easily unless we stored it.
        // `GeminiRemoteDataSourceImpl` doesn't hold the API key as state, it's passed in methods.
        // But `sendMessage` definition in interface doesn't take API Key!
        // This is a flaw in the current `sendMessage` design if we need to upload files dynamically.
        // `ChatSession` remembers the model and key internally? No, `ChatSession` is from the SDK.
        // The SDK's `ChatSession` doesn't expose a way to upload files using its internal key.

        // OPTION 1: Read the image as bytes and use `DataPart` (inline). This doesn't require API key.
        // Limitations: Payload size. For a single image, it's usually fine (up to 20MB limit for request).
        final bytes = await image.readAsBytes();
        // Determine mime type (fallback to jpeg)
        String mimeType = 'image/jpeg';
        // final verifyBytes = await image.readAsBytes(); // Removed unused variable
        if (image.path.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (image.path.toLowerCase().endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        parts.add(DataPart(mimeType, bytes));
      }

      final response = await chatSession.sendMessage(Content.multi(parts));
      return response.text;
    } catch (e) {
      debugPrint('SendMessage error: $e');
      rethrow;
    }
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
      // 1. Log User Request
      await _cacheManager.logInteraction('user', prompt);

      // 2. Check for Smart Cache
      String? cachedName = await _cacheManager.getOrSyncCache(
        apiKey: apiKey,
        systemInstruction: systemInstruction,
        modelName: 'models/$model',
      );

      // 3. Generate Content via REST Helper
      final responseText = await _generateWithRest(
        apiKey: apiKey,
        systemInstruction: systemInstruction,
        contentParts: [
          {'text': prompt},
        ],
        model: model,
        cachedContent: cachedName,
        responseMimeType: responseMimeType,
      );

      if (responseText != null) {
        // 4. Log Model Response
        await _cacheManager.logInteraction('model', responseText);
      }

      return responseText;
    } catch (e) {
      debugPrint('Gemini generateContent error: $e');
      throw Exception('Failed to generate content: $e');
    }
  }

  // Refactored helper to support JSON parsing
  Future<Map<String, dynamic>?> _postMultimodal({
    required String apiKey,
    required String systemInstruction,
    required List<Map<String, dynamic>> contentParts,
    String model = 'gemini-3-flash-preview',
    double temperature = 0.2,
    Map<String, dynamic>? responseSchema,
    String? cachedContent,
  }) async {
    final text = await _generateWithRest(
      apiKey: apiKey,
      systemInstruction: systemInstruction,
      contentParts: contentParts,
      model: model,
      temperature: temperature,
      responseSchema: responseSchema,
      cachedContent: cachedContent,
      responseMimeType: 'application/json',
    );

    if (text == null) return null;

    // Robust JSON extraction
    String cleanText = text.trim();
    if (cleanText.startsWith('```json')) {
      cleanText = cleanText.substring(7);
    }
    if (cleanText.endsWith('```')) {
      cleanText = cleanText.substring(0, cleanText.length - 3);
    }

    try {
      return json.decode(cleanText.trim());
    } catch (e) {
      debugPrint('JSON decode error in Gemini response: $e\nOriginal: $text');
      return null;
    }
  }

  /// Unified REST Helper for Gemini 3
  Future<String?> _generateWithRest({
    required String apiKey,
    required String systemInstruction,
    required List<Map<String, dynamic>> contentParts,
    required String model,
    double? temperature,
    String? responseMimeType,
    Map<String, dynamic>? responseSchema,
    String? cachedContent,
  }) async {
    final endpoint = model == 'gemini-3-flash-preview'
        ? _generateUrl
        : 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

    final uri = Uri.parse('$endpoint?key=$apiKey');

    final generationConfig = <String, dynamic>{};
    if (temperature != null) generationConfig['temperature'] = temperature;
    if (responseMimeType != null) {
      generationConfig['responseMimeType'] = responseMimeType;
    }
    if (responseSchema != null) {
      generationConfig['responseSchema'] = responseSchema;
    }

    // Conditional Context Injection
    final systemParts = <Map<String, dynamic>>[
      {'text': systemInstruction},
    ];

    if (cachedContent == null) {
      systemParts.add({'text': await _cacheManager.getFormattedContext()});
    }

    final bodyMap = {
      'systemInstruction': {'parts': systemParts},
      'contents': [
        {'parts': contentParts},
      ],
      if (generationConfig.isNotEmpty) 'generationConfig': generationConfig,
    };

    if (cachedContent != null) {
      bodyMap['cachedContent'] = cachedContent;
    }

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bodyMap),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'];
        }
      }
      return null;
    } else {
      debugPrint(
        'Gemini REST failed: ${response.statusCode} - ${response.body}',
      );
      throw Exception('Gemini REST failed: ${response.statusCode}');
    }
  }

  @override
  Future<String?> uploadFile({
    required String apiKey,
    required File file,
  }) async {
    try {
      final int fileSize = await file.length();

      // 1. Initialize request (Resumable Upload Session)
      final startUri = Uri.parse('$_uploadUrl?key=$apiKey');

      final startResponse = await http.post(
        startUri,
        headers: {
          'X-Goog-Upload-Protocol': 'resumable',
          'X-Goog-Upload-Command': 'start',
          'X-Goog-Upload-Header-Content-Length': '$fileSize',
          'X-Goog-Upload-Header-Content-Type': 'video/mp4',
          'Content-Type': 'application/json',
        },
        body: json.encode({'display_name': file.path.split('/').last}),
      );

      if (startResponse.statusCode != 200) {
        debugPrint('Upload Init Failed: ${startResponse.body}');
        throw Exception(
          'Failed to initiate upload: ${startResponse.statusCode}',
        );
      }

      // 2. Extract upload URL
      final uploadUrl = startResponse.headers['x-goog-upload-url'];
      if (uploadUrl == null) {
        throw Exception('No upload URL received from Gemini API');
      }

      // 3. Binary file transfer (PUT)
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Length': '$fileSize',
          'X-Goog-Upload-Offset': '0',
          'X-Goog-Upload-Command': 'upload, finalize',
        },
        body: await file.readAsBytes(),
      );

      if (uploadResponse.statusCode == 200) {
        final jsonData = json.decode(uploadResponse.body);
        return jsonData['file']['uri'];
      } else {
        debugPrint('File Upload Failed: ${uploadResponse.body}');
        throw Exception(
          'Upload failed with status ${uploadResponse.statusCode}',
        );
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

    debugPrint('Waiting for file processing: $name');
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
            throw Exception('File processing failed');
          }
        }
      } catch (e) {
        debugPrint('Error checking file state: $e');
        if (e.toString().contains('File processing failed')) rethrow;
      }
      await Future.delayed(const Duration(seconds: 2));
      attempts++;
    }
    throw Exception('File processing timeout');
  }

  @override
  Future<Map<String, dynamic>?> analyzeInterSet({
    required String apiKey,
    required String systemInstruction,
    required Map<String, dynamic> inputContext,
    required String rgbUri,
    String? controlNetUri,
    String mimeType = 'video/mp4',
    String model = 'gemini-3-flash-preview',
  }) async {
    try {
      final contentParts = [
        {'text': json.encode(inputContext)},
        {
          'file_data': {'mime_type': mimeType, 'file_uri': rgbUri},
        },
        if (controlNetUri != null)
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

      // Define Schema for Baseline Assessment
      final responseSchema = {
        "type": "OBJECT",
        "properties": {
          "stability_score": {"type": "INTEGER"},
          "mobility_score": {"type": "INTEGER"},
          "alignment_issues": {
            "type": "ARRAY",
            "items": {"type": "STRING"},
          },
          "recommendation": {"type": "STRING"},
        },
        "required": [
          "stability_score",
          "mobility_score",
          "alignment_issues",
          "recommendation",
        ],
      };

      return await _postMultimodal(
        apiKey: apiKey,
        systemInstruction: systemInstruction,
        contentParts: contentParts,
        model: model,
        responseSchema: responseSchema,
      );
    } catch (e) {
      debugPrint('Baseline Analyst Error: $e');
      rethrow;
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

  @override
  Future<String?> analyzeImage({
    required String apiKey,
    required String prompt,
    required File image,
    String model = 'gemini-3-flash-preview',
  }) async {
    try {
      // 1. Upload File
      final imageUri = await uploadFile(apiKey: apiKey, file: image);
      if (imageUri == null) throw Exception('Failed to upload image');

      await waitForFileActive(apiKey: apiKey, fileUri: imageUri);

      // 2. Generate Content using REST to get text response
      final endpoint =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      final contentParts = [
        {'text': prompt},
        {
          'file_data': {'mime_type': 'image/jpeg', 'file_uri': imageUri},
        },
      ];

      final body = json.encode({
        'contents': [
          {'parts': contentParts},
        ],
      });

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'];
          }
        }
        return null;
      } else {
        debugPrint(
          'Analyze Image Failed: ${response.statusCode} ${response.body}',
        );
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Analyze Image Error: $e');
      rethrow;
    }
  }
}
