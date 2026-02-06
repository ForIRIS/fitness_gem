import 'package:google_generative_ai/google_generative_ai.dart';

/// Wrapper for Google's GenerativeModel to allow mocking
abstract class GeminiWrapper {
  Future<GenerateContentResponse> generateContent(Iterable<Content> prompt);
}

class GeminiWrapperImpl implements GeminiWrapper {
  final GenerativeModel _model;

  GeminiWrapperImpl(this._model);

  @override
  Future<GenerateContentResponse> generateContent(Iterable<Content> prompt) {
    return _model.generateContent(prompt);
  }
}
