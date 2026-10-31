// lib/services/gemini_service.dart
//
// Wrapper tipis di atas Gemini REST API (google_generative_ai package).
// Menangani: inisialisasi model, pengiriman riwayat percakapan,
// dan stream response.

import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/assistant_prompts.dart';

class GeminiService {
  GeminiService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          systemInstruction: Content.system(AssistantPrompts.systemPrompt),
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          ),
        );

  final GenerativeModel _model;

  /// Mengirim seluruh riwayat percakapan dan mendapat respons streaming.
  /// [history] adalah daftar pesan sebelumnya (tanpa pesan user terbaru).
  /// [userMessage] adalah pesan terbaru dari pengguna.
  Stream<String> sendMessage({
    required List<Content> history,
    required String userMessage,
  }) async* {
    final chat = _model.startChat(history: history);
    final response = chat.sendMessageStream(Content.text(userMessage));

    await for (final chunk in response) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  /// Mengonversi daftar [ChatMessage] internal menjadi format [Content]
  /// yang dibutuhkan oleh Gemini SDK.
  static List<Content> toGeminiHistory(List<({String role, String content})> messages) {
    return messages.map((m) {
      return m.role == 'user'
          ? Content.text(m.content)
          : Content.model([TextPart(m.content)]);
    }).toList();
  }
}
