// lib/main.dart
//
// Entry point aplikasi. Mendaftarkan GeminiService dan AssistantController
// ke dalam Provider tree.
//
// ⚠️  KEAMANAN: Jangan pernah hardcode API Key di source code produksi!
//    Gunakan flutter_dotenv atau --dart-define untuk inject key saat build.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/assistant_controller.dart';
import 'services/gemini_service.dart';
import 'views/assistant_chat_page.dart';

// Ambil API Key dari environment variable yang di-inject saat build:
//   flutter run --dart-define=GEMINI_API_KEY=your_key_here
const _geminiApiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: 'YOUR_GEMINI_API_KEY', // ganti untuk development lokal
);

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Satu instance GeminiService untuk seluruh app
        Provider<GeminiService>(
          create: (_) => GeminiService(apiKey: _geminiApiKey),
        ),
        // AssistantController mengonsumsi GeminiService
        ChangeNotifierProxyProvider<GeminiService, AssistantController>(
          create: (context) => AssistantController(
            geminiService: context.read<GeminiService>(),
          ),
          update: (_, gemini, prev) => prev ?? AssistantController(geminiService: gemini),
        ),
      ],
      child: const CollectorTradeApp(),
    ),
  );
}

class CollectorTradeApp extends StatelessWidget {
  const CollectorTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collector & Trade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      home: const AssistantChatPage(),
    );
  }
}
