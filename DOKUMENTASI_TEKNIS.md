# 📋 Dokumentasi Teknis — Collector & Trade Assistant
## Capstone Project: AI-Powered Flutter App

---

## 1. Arsitektur Aplikasi

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                              │
│                                                                 │
│  ┌──────────────┐   notify   ┌──────────────────────────────┐  │
│  │  Chat Page   │◄──────────│   AssistantController        │  │
│  │  (View)      │            │   (ChangeNotifier)           │  │
│  └──────────────┘            │                              │  │
│         │                    │  - messages: List<ChatMsg>   │  │
│         │ read/watch         │  - isLoading: bool           │  │
│         │                    │  - sendMessage()             │  │
│         │                    │  - clearConversation()       │  │
│         │                    └──────────┬───────────────────┘  │
│         │                               │ calls                │
│         │                    ┌──────────▼───────────────────┐  │
│         │                    │   GeminiService              │  │
│         │                    │                              │  │
│         │                    │  - sendMessage() → Stream    │  │
│         │                    │  - toGeminiHistory()         │  │
│         │                    └──────────┬───────────────────┘  │
│         │                               │ HTTPS/REST           │
└─────────┼───────────────────────────────┼─────────────────────-┘
          │                               ▼
          │                    ┌──────────────────────┐
          │                    │   Gemini 1.5 Flash   │
          │                    │   (Google AI API)    │
          │                    └──────────────────────┘
          │
          ▼ renders
   flutter_markdown → Tabel, Bold, Heading, Blockquote
```

---

## 2. Implementasi API / Model AI

### Model yang Digunakan
| Parameter | Nilai |
|---|---|
| **Provider** | Google AI (Gemini) |
| **Model ID** | `gemini-1.5-flash` |
| **Flutter Package** | `google_generative_ai: ^0.4.3` |
| **Mode Request** | Streaming (`sendMessageStream`) |
| **Temperature** | 0.7 (kreatif tapi tetap faktual) |
| **Max Output Tokens** | 2048 |

### Cara Mendapatkan API Key
1. Buka [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. Buat API Key baru (gratis untuk kuota dev)
3. Inject saat build: `flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY`

### Alur Request ke Gemini
```
User ketik pesan
       │
       ▼
AssistantController.sendMessage(text)
       │
       ├─ Tambah ChatMessage(role: user) ke list
       ├─ Tambah ChatMessage(role: assistant, isLoading: true)
       │
       ▼
GeminiService.sendMessage(history, userMessage)
       │
       │  Bangun: GenerativeModel + systemInstruction
       │  Buat: ChatSession(history)
       │  Kirim: sendMessageStream(Content.text(userMessage))
       │
       ▼
Stream<GenerateContentResponse>
       │
       ├─ yield chunk.text (real-time streaming)
       │
       ▼
AssistantController menerima chunk
       │
       ├─ Append ke StringBuffer
       ├─ Update ChatMessage dengan konten partial
       ├─ notifyListeners() → UI re-render
       │
       ▼ (stream selesai)
isLoading = false → notifyListeners()
```

---

## 3. UI/UX Integration — Parsing Respons AI ke Antarmuka

### Tantangan
Respons AI mengandung format Markdown (tabel, bold, heading, blockquote). Flutter tidak me-render Markdown secara native.

### Solusi: `flutter_markdown`
Package `flutter_markdown: ^0.7.3` digunakan untuk me-render teks Markdown menjadi widget Flutter.

```dart
// Di dalam _ChatBubble widget:
MarkdownBody(
  data: message.content, // String Markdown dari AI
  styleSheet: MarkdownStyleSheet(
    tableHead:  TextStyle(fontWeight: FontWeight.bold),
    tableBody:  TextStyle(fontSize: 13),
    tableBorder: TableBorder.all(color: Colors.grey.shade300),
    // ... styling lainnya
  ),
)
```

### Elemen Markdown yang Dirender Otomatis
| Syntax Markdown | Hasil di UI |
|---|---|
| `**teks**` | **Teks tebal** |
| `## Heading` | Judul besar |
| `\| col \| col \|` | Tabel dengan border |
| `> blockquote` | Kotak biru muda (deskripsi penawaran) |
| `- item` | Bullet list |
| `⭐⭐⭐⭐⭐` | Emoji bintang rating |

### Streaming Real-time
Respons muncul **kata per kata** (seperti ChatGPT) karena menggunakan `Stream<String>`:
```dart
// GeminiService
await for (final chunk in response) {
  yield chunk.text; // dikirim per token
}

// AssistantController
await for (final chunk in _geminiService.sendMessage(...)) {
  buffer.write(chunk);
  _updateAssistantMessage(id, buffer.toString()); // update UI tiap chunk
  notifyListeners(); // rebuild widget
}
```

---

## 4. Struktur File Proyek

```
lib/
├── main.dart                        # Entry point + Provider setup
├── constants/
│   └── assistant_prompts.dart       # System prompt + initial greeting
├── models/
│   └── chat_message.dart            # Model data pesan
├── services/
│   └── gemini_service.dart          # Wrapper Gemini API
├── controllers/
│   └── assistant_controller.dart    # Logika bisnis + state
└── views/
    └── assistant_chat_page.dart     # UI halaman chat

test/
└── assistant_controller_test.dart   # Skenario testing percakapan

pubspec.yaml                         # Dependencies
```

---

## 5. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2             # State management
  google_generative_ai: ^0.4.3 # Gemini AI SDK
  flutter_markdown: ^0.7.3     # Render Markdown output AI
  uuid: ^4.4.0                 # Generate ID unik per pesan
```

---

## 6. Keamanan API Key

| ❌ Jangan | ✅ Lakukan |
|---|---|
| Hardcode key di source code | Gunakan `--dart-define=GEMINI_API_KEY=...` |
| Commit key ke Git | Tambahkan `.env` ke `.gitignore` |
| Expose key di client-side produksi | Gunakan backend proxy (Firebase Functions) |

---

## 7. Skenario Testing (Demo Capstone)

### Skenario 1
- **Input User:** *"Halo, saya punya Nendoroid Gojo Satoru kondisi MIB, kira-kira harganya berapa ya? Saya mau tukar sama action figure Chainsaw Man."*
- **Expected Output AI:**
  - ✅ Identifikasi: Nendoroid Gojo Satoru #1238
  - ✅ Kondisi MIB dianalisis dengan benar
  - ✅ Estimasi kisaran Rp 450.000 – Rp 650.000
  - ✅ Draft teks penawaran WTT
  - ✅ Tabel saran: Nendoroid Denji, Power, S.H. Figuarts

### Skenario 2
- **Input User:** *"Saya punya Funko POP! Luffy Chase Edition masih MISB. Mau ditukar sama Pokémon card PSA 10."*
- **Expected Output AI:**
  - ✅ Chase Edition diidentifikasi sebagai rare (1:6)
  - ✅ Nilai lebih tinggi dari regular (Rp 600K–950K)
  - ✅ Tabel kartu Pokémon PSA yang setara nilai
  - ✅ Disclaimer "estimasi kisaran" selalu muncul

---

*Dokumentasi ini dibuat sebagai bagian dari pengumpulan Capstone Project AI Agent.*
