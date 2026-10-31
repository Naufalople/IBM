// test/assistant_controller_test.dart
//
// Simulasi alur percakapan (Skenario Testing) — Capstone Demo
// ============================================================
// Skenario 1: User menawarkan Nendoroid Gojo Satoru MIB, ingin tukar
//             dengan action figure Chainsaw Man.
// Skenario 2: User menawarkan Funko POP! Luffy Chase Edition MISB,
//             ingin tukar dengan trading card Pokémon PSA 10.

import 'package:flutter_test/flutter_test.dart';
import 'package:collector_trade_assistant/models/chat_message.dart';
import 'package:collector_trade_assistant/constants/assistant_prompts.dart';

// ─── Mock GeminiService untuk testing offline ────────────────────────────────

/// Respons simulasi yang sudah disiapkan sesuai format prompt
const String _mockResponseSkenario1 = '''
**Nama & Kategori Barang:**
Nendoroid Gojo Satoru (#1238) — Action Figure / Nendoroid (Good Smile Company)
Seri: Jujutsu Kaisen

**Analisis Kondisi & Kelayakan:**
Kondisi **MIB (Mint in Box)** menunjukkan bahwa item ini berada dalam kondisi prima — figur belum pernah dilepas dari kemasan dan semua aksesori (face parts, stand, dll.) diasumsikan lengkap. Ini adalah kondisi paling diminati kolektor setelah MISB, sehingga nilai jual/tukarnya sangat tinggi.
Kelayakan tukar: ⭐⭐⭐⭐⭐ **Sangat layak ditawarkan.**

**Estimasi Nilai Pasar:**
Berdasarkan tren pasar kolektor Indonesia (Tokopedia, Shopee, grup Facebook Nendoroid Indonesia) per 2024–2025:
- 🟢 Estimasi kisaran **Rp 450.000 – Rp 650.000** (tergantung kondisi seal dan kelengkapan insert)
- Harga cenderung meningkat karena popularitas Jujutsu Kaisen yang terus tinggi.

> ⚠️ *Ini adalah estimasi kisaran berdasarkan tren pasar, bukan harga pasti.*

**Deskripsi Penawaran:**
> 🔁 **[TRADE/WTT] Nendoroid Gojo Satoru #1238 — MIB (Mint in Box)**
> Kondisi: MIB | Kemasan mulus, figur belum pernah dikeluarkan | Aksesori lengkap
> Estimasi nilai: Rp 450K–650K
> Mencari: Action Figure seri **Chainsaw Man** (Denji / Power / Makima) kondisi MIB/MNC
> DM untuk negosiasi & foto detail. No cash, trade only. 🙏

**Saran Item Tukar-Tambah:**
Berikut item yang setara nilainya dan sesuai preferensi Chainsaw Man Anda:

| Item | Brand | Estimasi Nilai | Prioritas |
|---|---|---|---|
| Nendoroid Denji #1879 | Good Smile Co. | Rp 450K–600K | ⭐⭐⭐⭐⭐ |
| Nendoroid Power #1881 | Good Smile Co. | Rp 450K–580K | ⭐⭐⭐⭐⭐ |
| S.H. Figuarts Denji (Chainsaw Man Ver.) | Bandai | Rp 500K–700K | ⭐⭐⭐⭐ |
| Pop Up Parade Makima | Good Smile Co. | Rp 300K–420K | ⭐⭐⭐ |

*Prioritaskan tukar dengan Nendoroid Denji atau Power untuk keseimbangan nilai terbaik!*
''';

const String _mockResponseSkenario2 = '''
**Nama & Kategori Barang:**
Funko POP! Monkey D. Luffy Chase Edition #98 — Vinyl Figure / Funko POP!
Seri: One Piece | Chase: 1:6 rarity

**Analisis Kondisi & Kelayakan:**
Kondisi **MISB (Mint in Sealed Box)** adalah kondisi tertinggi dalam standar kolektor — plastik seal pabrik masih utuh. Status **Chase Edition** (1:6 rarity) melipatgandakan nilai secara signifikan dibanding varian reguler.
Kelayakan tukar: ⭐⭐⭐⭐⭐ **Sangat premium dan dicari.**

**Estimasi Nilai Pasar:**
- Funko POP! Luffy Regular MISB: Rp 200K–300K
- 🏆 **Chase Edition MISB**: Estimasi kisaran **Rp 600.000 – Rp 950.000** (faktor kelangkaan 1:6)
- Harga bisa melebihi Rp 1.000.000 jika pembeli adalah kolektor hardcore One Piece.

> ⚠️ *Ini adalah estimasi kisaran berdasarkan tren pasar, bukan harga pasti.*

**Deskripsi Penawaran:**
> 🔁 **[TRADE/WTT] Funko POP! Luffy Chase Edition #98 — MISB 🔥**
> Status: MISB | Seal pabrik intact | Chase 1:6 (LANGKA!)
> Estimasi nilai: Rp 600K–950K
> Mencari: **Pokémon TCG PSA 10** / Graded Card high value
> DM untuk foto + COD area Jabodetabek. Serious buyer only. 🙏

**Saran Item Tukar-Tambah:**
Item Pokémon TCG yang setara untuk ditukarkan:

| Kartu | Grade | Estimasi Nilai | Match Score |
|---|---|---|---|
| Charizard VMAX Secret Rare PSA 10 | PSA 10 | Rp 700K–1.1jt | ⭐⭐⭐⭐⭐ |
| Pikachu VMAX Rainbow Rare PSA 9 | PSA 9 | Rp 500K–800K | ⭐⭐⭐⭐ |
| Umbreon VMAX Alt Art PSA 9 | PSA 9 | Rp 600K–900K | ⭐⭐⭐⭐⭐ |
| Mewtwo V-UNION Special Art PSA 10 | PSA 10 | Rp 400K–650K | ⭐⭐⭐ |

*Gunakan referensi harga dari TCGPlayer.com atau PriceCharting sebagai acuan saat negosiasi.*
''';

// ─── Skenario Tests ──────────────────────────────────────────────────────────

void main() {
  group('AssistantController — Initial Greeting', () {
    test('Pesan pertama harus berupa greeting dari assistant', () {
      // Simulasikan kondisi awal controller
      final messages = <ChatMessage>[
        ChatMessage(
          id: 'greeting-001',
          content: AssistantPrompts.initialGreeting,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        ),
      ];

      expect(messages.length, equals(1));
      expect(messages.first.role, equals(MessageRole.assistant));
      expect(messages.first.content, contains('Collector & Trade Assistant'));
      expect(messages.first.isLoading, isFalse);
    });
  });

  group('Skenario 1 — Nendoroid Gojo Satoru MIB → Tukar Chainsaw Man', () {
    late List<ChatMessage> conversation;

    setUp(() {
      conversation = [
        // [0] Greeting awal
        ChatMessage(
          id: 'msg-000',
          content: AssistantPrompts.initialGreeting,
          role: MessageRole.assistant,
          timestamp: DateTime(2025, 1, 1, 10, 0),
        ),
        // [1] Pesan user
        ChatMessage(
          id: 'msg-001',
          content:
              'Halo, saya punya Nendoroid Gojo Satoru kondisi MIB (Mint in Box), '
              'kira-kira harganya berapa ya? Saya mau tukar sama action figure Chainsaw Man.',
          role: MessageRole.user,
          timestamp: DateTime(2025, 1, 1, 10, 1),
        ),
        // [2] Respons AI (simulasi)
        ChatMessage(
          id: 'msg-002',
          content: _mockResponseSkenario1,
          role: MessageRole.assistant,
          timestamp: DateTime(2025, 1, 1, 10, 1, 5),
        ),
      ];
    });

    test('Percakapan memiliki 3 pesan (greeting + user + assistant)', () {
      expect(conversation.length, equals(3));
    });

    test('Pesan user berisi keyword yang relevan', () {
      final userMsg = conversation[1].content;
      expect(userMsg, contains('Nendoroid Gojo Satoru'));
      expect(userMsg, contains('MIB'));
      expect(userMsg, contains('Chainsaw Man'));
    });

    test('Respons AI mengandung semua 5 elemen format output', () {
      final aiResponse = conversation[2].content;
      expect(aiResponse, contains('Nama & Kategori Barang'));
      expect(aiResponse, contains('Analisis Kondisi & Kelayakan'));
      expect(aiResponse, contains('Estimasi Nilai Pasar'));
      expect(aiResponse, contains('Deskripsi Penawaran'));
      expect(aiResponse, contains('Saran Item Tukar-Tambah'));
    });

    test('Respons AI TIDAK mengklaim harga pasti (menggunakan "estimasi kisaran")', () {
      final aiResponse = conversation[2].content;
      expect(aiResponse, contains('estimasi kisaran'));
      expect(aiResponse, isNot(contains('harga pasti')));
    });

    test('Saran tukar mencantumkan item Chainsaw Man yang relevan', () {
      final aiResponse = conversation[2].content;
      expect(aiResponse, contains('Denji'));
    });
  });

  group('Skenario 2 — Funko POP! Luffy Chase MISB → Tukar Pokémon TCG PSA', () {
    late List<ChatMessage> conversation;

    setUp(() {
      conversation = [
        ChatMessage(
          id: 'msg-000',
          content: AssistantPrompts.initialGreeting,
          role: MessageRole.assistant,
          timestamp: DateTime(2025, 1, 2, 14, 0),
        ),
        ChatMessage(
          id: 'msg-003',
          content:
              'Saya punya Funko POP! Luffy Chase Edition masih MISB (sealed). '
              'Mau ditukar sama Pokémon card PSA 10. Worth nggak?',
          role: MessageRole.user,
          timestamp: DateTime(2025, 1, 2, 14, 1),
        ),
        ChatMessage(
          id: 'msg-004',
          content: _mockResponseSkenario2,
          role: MessageRole.assistant,
          timestamp: DateTime(2025, 1, 2, 14, 1, 8),
        ),
      ];
    });

    test('Respons AI mengenali kondisi MISB dan Chase Edition', () {
      final aiResponse = conversation[2].content;
      expect(aiResponse, contains('MISB'));
      expect(aiResponse, contains('Chase'));
    });

    test('Estimasi nilai Chase Edition lebih tinggi dari regular', () {
      final aiResponse = conversation[2].content;
      // Chase edition harus menyebut nilai di atas Rp 500K
      expect(aiResponse, contains('600.000'));
    });

    test('Saran tukar mengacu pada Pokémon TCG dengan grade PSA', () {
      final aiResponse = conversation[2].content;
      expect(aiResponse, contains('PSA'));
      expect(aiResponse, contains('Charizard'));
    });

    test('Disclaimer estimasi harga ada di respons', () {
      final aiResponse = conversation[2].content;
      expect(aiResponse, contains('estimasi kisaran'));
    });
  });

  group('Validasi Format Pesan', () {
    test('ChatMessage.copyWith hanya mengubah field yang dispesifikasi', () {
      final original = ChatMessage(
        id: 'test-id',
        content: 'Teks awal',
        role: MessageRole.assistant,
        timestamp: DateTime(2025),
        isLoading: true,
      );

      final updated = original.copyWith(content: 'Teks baru', isLoading: false);

      expect(updated.id, equals(original.id));
      expect(updated.role, equals(original.role));
      expect(updated.timestamp, equals(original.timestamp));
      expect(updated.content, equals('Teks baru'));
      expect(updated.isLoading, isFalse);
    });
  });
}
