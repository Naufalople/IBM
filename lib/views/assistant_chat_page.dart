// lib/views/assistant_chat_page.dart
//
// Halaman UI lengkap untuk fitur Collector & Trade Assistant.
// Menggunakan: Provider + flutter_markdown untuk render output AI.

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../controllers/assistant_controller.dart';
import '../models/chat_message.dart';

class AssistantChatPage extends StatefulWidget {
  const AssistantChatPage({super.key});

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(AssistantController controller) async {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    await controller.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Collector & Trade Assistant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Consumer<AssistantController>(
            builder: (context, controller, _) => IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset percakapan',
              onPressed: () {
                controller.clearConversation();
                _scrollToBottom();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Daftar pesan ──
          Expanded(
            child: Consumer<AssistantController>(
              builder: (context, controller, _) {
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    return _ChatBubble(message: controller.messages[index]);
                  },
                );
              },
            ),
          ),

          // ── Error banner ──
          Consumer<AssistantController>(
            builder: (context, controller, _) {
              if (controller.errorMessage == null) return const SizedBox.shrink();
              return Container(
                color: Colors.red.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Input bar ──
          _InputBar(
            controller: _inputController,
            onSend: (text) {
              final assistantController = context.read<AssistantController>();
              _handleSend(assistantController);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Widget: Chat Bubble ─────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: message.isLoading && message.content.isEmpty
            // Animasi loading dot
            ? const _TypingIndicator()
            : isUser
                ? SelectableText(
                    message.content,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 14,
                    ),
                  )
                // Render Markdown untuk respons AI
                : MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 14, height: 1.5),
                      h1: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                      tableHead: const TextStyle(fontWeight: FontWeight.bold),
                      tableBody: const TextStyle(fontSize: 13),
                      tableBorder: TableBorder.all(color: Colors.grey.shade300),
                      blockquoteDecoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border(
                          left: BorderSide(color: Colors.blue.shade200, width: 3),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}

// ─── Widget: Typing Indicator ────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animController,
      child: const Text(
        '● ● ●',
        style: TextStyle(fontSize: 16, letterSpacing: 4, color: Colors.grey),
      ),
    );
  }
}

// ─── Widget: Input Bar ───────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Deskripsikan koleksi Anda...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Consumer<AssistantController>(
              builder: (context, assistantCtrl, _) => IconButton.filled(
                onPressed: assistantCtrl.isLoading
                    ? null
                    : () => onSend(controller.text),
                icon: assistantCtrl.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
