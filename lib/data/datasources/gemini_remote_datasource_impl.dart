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
  Future<Map<String, dynamic>?> analyzeInterSet({
    required String apiKey,
    required String systemInstruction,
    required Map<String, dynamic> inputContext,
    required String rgbUri,
    required String controlNetUri,
    String model = 'gemini-3-flash-preview',
  }) async {
    try {
      // Note: Using the specific endpoint for the model passed, or default
      final endpoint = model == 'gemini-3-flash-preview'
          ? _generateUrl
          : 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

      final uri = Uri.parse('$endpoint?key=$apiKey');

      final analystBody = json.encode({
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
        'contents': [
          {
            'parts': [
              {'text': json.encode(inputContext)},
              {
                'file_data': {'mime_type': 'video/mp4', 'file_uri': rgbUri},
              },
              {
                'file_data': {
                  'mime_type': 'video/mp4',
                  'file_uri': controlNetUri,
                },
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        },
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: analystBody,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'];
            if (text != null) {
              return json.decode(text);
            }
          }
        }
      } else {
        debugPrint('Analyst failed: ${response.body}');
        throw Exception('Analyst failed: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('Analyst Error: $e');
      rethrow;
    }
  }
}
