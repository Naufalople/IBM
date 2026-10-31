// lib/controllers/assistant_controller.dart
//
// Controller berbasis ChangeNotifier (kompatibel dengan Provider).
// Jika proyek menggunakan Bloc, lihat versi Bloc di bagian bawah komentar.

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/chat_message.dart';
import '../constants/assistant_prompts.dart';
import '../services/gemini_service.dart';

class AssistantController extends ChangeNotifier {
  AssistantController({required GeminiService geminiService})
      : _geminiService = geminiService {
    _initializeGreeting();
  }

  final GeminiService _geminiService;
  final _uuid = const Uuid();

  // ─── State ──────────────────────────────────────────────────────────────────
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Inisialisasi ────────────────────────────────────────────────────────────
  /// Dipanggil sekali saat controller dibuat.
  /// Memasukkan pesan sambutan awal dari bot tanpa memanggil API.
  void _initializeGreeting() {
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        content: AssistantPrompts.initialGreeting,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      ),
    );
  }

  // ─── Kirim Pesan ─────────────────────────────────────────────────────────────
  Future<void> sendMessage(String userInput) async {
    if (userInput.trim().isEmpty || _isLoading) return;

    _errorMessage = null;

    // 1. Tambahkan pesan pengguna ke daftar
    _messages.add(ChatMessage(
      id: _uuid.v4(),
      content: userInput.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    ));

    // 2. Tambahkan placeholder loading untuk respons bot
    final assistantId = _uuid.v4();
    _messages.add(ChatMessage(
      id: assistantId,
      content: '',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      isLoading: true,
    ));

    _isLoading = true;
    notifyListeners();

    // 3. Bangun riwayat percakapan (kecualikan pesan greeting awal dan placeholder)
    final history = _buildGeminiHistory();

    // 4. Streaming respons dari Gemini
    final buffer = StringBuffer();
    try {
      await for (final chunk in _geminiService.sendMessage(
        history: history,
        userMessage: userInput.trim(),
      )) {
        buffer.write(chunk);
        _updateAssistantMessage(assistantId, buffer.toString(), isLoading: true);
        notifyListeners();
      }
      // Selesai streaming — tandai sebagai tidak loading
      _updateAssistantMessage(assistantId, buffer.toString(), isLoading: false);
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke AI. Silakan coba lagi.';
      _updateAssistantMessage(
        assistantId,
        '⚠️ Maaf, terjadi kesalahan saat menghubungi asisten. Silakan coba lagi.',
        isLoading: false,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Helper ──────────────────────────────────────────────────────────────────

  void _updateAssistantMessage(String id, String content, {required bool isLoading}) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(
        content: content,
        isLoading: isLoading,
      );
    }
  }

  /// Membangun riwayat untuk dikirim ke Gemini.
  /// Mengabaikan: pesan greeting statis pertama (indeks 0)
  /// dan pesan placeholder loading terakhir.
  List<Content> _buildGeminiHistory() {
    // Ambil semua pesan kecuali: greeting awal (idx 0) dan placeholder terakhir
    final relevant = _messages
        .skip(1) // lewati greeting statis
        .where((m) => !m.isLoading && m.content.isNotEmpty)
        .toList();

    // Buang pesan user terakhir karena akan dikirim sebagai current message
    if (relevant.isNotEmpty && relevant.last.role == MessageRole.user) {
      relevant.removeLast();
    }

    return GeminiService.toGeminiHistory(
      relevant
          .map((m) => (
                role: m.role == MessageRole.user ? 'user' : 'model',
                content: m.content,
              ))
          .toList(),
    );
  }

  /// Reset percakapan ke kondisi awal (hanya greeting).
  void clearConversation() {
    _messages.clear();
    _errorMessage = null;
    _isLoading = false;
    _initializeGreeting();
    notifyListeners();
  }
}
