# 🏴‍☠️ OP Card Pro — Engineering Documentation

> **One Piece TCG Companion App** | Flutter | Dart SDK ^3.11.5 | v1.0.0+1

---

## 1. Project Overview

**op_cardpro** adalah aplikasi mobile Flutter untuk pemain One Piece TCG (Trading Card Game). Fitur utama:

- 📦 **Card Database** — Browse semua set OP-01 s/d OP-15, EB-01~04, PRB-01~02, ST-01~30
- 🃏 **Deck Builder** — Build & edit deck dengan validasi warna Leader
- 🏆 **Tournament Manager** — Swiss pairing + Top Cut bracket
- 🧪 **Testing Lab** — Solo playmat simulator (shuffle, draw, DON!!, attack)
- 📲 **QR Registration** — Generate/Scan QR untuk registrasi turnamen

---

## 2. Architecture

### 2.1 Layer Architecture

```
lib/
├── main.dart                    # Entry point, MaterialApp setup
├── theme/
│   └── app_theme.dart           # Design system, color tokens
├── models/                      # Pure Dart data models (no Flutter deps kecuali CardModel)
│   ├── card_model.dart
│   ├── set_model.dart
│   ├── deck_model.dart
│   ├── tournament_model.dart
│   └── test_session_model.dart
├── services/
│   └── data_service.dart        # Singleton service, data access & persistence
├── screens/                     # UI screens (StatefulWidget/StatelessWidget)
│   ├── main_tab_screen.dart     # Root CupertinoTabScaffold (5 tabs)
│   ├── home_screen.dart
│   ├── card_list_screen.dart
│   ├── deck_builder_screen.dart
│   ├── deck_editor_screen.dart
│   ├── detail_screen.dart
│   ├── profile_screen.dart
│   ├── about_screen.dart
│   ├── testing/
│   │   ├── testing_lab_screen.dart
│   │   ├── deck_test_screen.dart
│   │   ├── playmat_view.dart
│   │   ├── how_to_play_screen.dart
│   │   └── preset_decks.dart
│   └── tournament/
│       ├── tournament_list_screen.dart
│       ├── tournament_detail_screen.dart
│       ├── create_tournament_sheet.dart
│       ├── deck_qr_screen.dart
│       └── qr_scanner_screen.dart
└── widgets/
    ├── card_item.dart
    └── set_card_widget.dart
```

### 2.2 Navigation Structure

```
CupertinoTabScaffold (MainTabScreen)
├── Tab 0: HomeScreen          → CardListScreen → DetailScreen
├── Tab 1: DeckBuilderScreen   → DeckEditorScreen → DeckQrScreen
├── Tab 2: TournamentListScreen → TournamentDetailScreen
├── Tab 3: TestingLabScreen    → DeckTestScreen → PlaymatView
└── Tab 4: ProfileScreen       → AboutScreen
```

### 2.3 State Management Pattern

**Tidak menggunakan Provider/Riverpod/Bloc.** State dikelola secara lokal:

- `StatefulWidget` dengan `setState()` untuk UI state
- `DataService` singleton sebagai in-memory cache & persistence layer
- Data dipass antar screen via constructor parameter

> ⚠️ **Untuk fitur baru yang complex**, pertimbangkan menambahkan `provider` atau `riverpod`. Saat ini aman untuk fitur screen-level saja.

---

## 3. Data Layer

### 3.1 Storage Strategy

| Data | Storage | Key |
|------|---------|-----|
| Card database | Flutter Assets (JSON) | `assets/data/{SET}/cards.json` |
| Set index | Flutter Assets (JSON) | `assets/data/sets_index.json` |
| Saved decks | SharedPreferences | `op_cardpro_decks` |
| Tournaments | SharedPreferences | `op_cardpro_tournaments` |
| Owned tournament IDs | SharedPreferences | `op_cardpro_owned_tournaments` |
| Image cache | flutter_cache_manager | Auto-managed |

> ⚠️ **SharedPreferences menyimpan JSON string.** Tidak ada SQLite/Isar database. Data bersifat lokal-only, tidak ada sync ke cloud.

### 3.2 DataService (Singleton)

```dart
// Akses dari mana saja
final ds = DataService();

// Load sets (cached setelah call pertama)
final sets = await ds.getSets();

// Load cards satu set
final cards = await ds.getCards('OP-01');

// Load SEMUA cards (semua set, bisa lambat pertama kali)
final all = await ds.getAllCards();

// Fast lookup by cardId
final card = ds.allCardsMap['OP01-001'];

// Deck persistence
await ds.saveDecks(deckList);
final decks = await ds.loadDecks();

// Tournament persistence
await ds.saveTournaments(tournaments);
final tournaments = await ds.loadTournaments();
```

**Caching Rules:**
- `_sets` di-cache seumur hidup app
- `_cardsBySet[setCode]` di-cache per-set
- `_allCards` di-cache setelah pertama kali `getAllCards()` dipanggil
- `_allCardsMap` diisi incremental setiap set di-load

### 3.3 Card ID Convention

```
Format: {SET}-{NUMBER}
Contoh: OP01-001, ST29-002

Parallel / reprint:
Format: {BASE_ID}_{suffix}
Contoh: OP01-001_p1, OP09-081_p2, OP06-100_r2

getBaseId("OP01-001_p1") → "OP01-001"
```

Deck builder menghitung copy limit dengan `getBaseCardCount()` — semua parallel dihitung bersama.

---

## 4. Data Schema

### 4.1 `cards.json` — Card Schema

```json
{
  "card_id": "OP01-001",
  "name": "Monkey.D.Luffy",
  "rarity": "L",
  "card_type": "Leader",
  "cost": null,
  "life": "5",
  "attribute": "Strike",
  "power": "5000",
  "counter": null,
  "color": "Red",
  "block_icon": "OP01",
  "type": "Straw Hat Crew",
  "effect": "[On Play] ...",
  "trigger": null,
  "card_set": "OP-01",
  "card_image_url": "https://..."
}
```

**Field Reference:**

| Field | Type | Nullable | Keterangan |
|-------|------|----------|------------|
| `card_id` | String | ❌ | Primary key, unique per kartu |
| `name` | String | ❌ | Nama kartu |
| `rarity` | String | ❌ | `L`, `SR`, `SEC`, `R`, `UC`, `C`, `DON` |
| `card_type` | String | ❌ | `Leader`, `Character`, `Event`, `Stage` |
| `cost` | String? | ✅ | DON!! cost untuk play (null untuk Leader) |
| `life` | String? | ✅ | Jumlah life (Leader only) |
| `attribute` | String? | ✅ | `Strike`, `Slash`, `Ranged`, `Special`, `Wisdom` |
| `power` | String? | ✅ | Nilai power numerik sebagai String |
| `counter` | String? | ✅ | Counter value (biasanya `+1000`, `+2000`) |
| `color` | String? | ✅ | `Red`, `Green`, `Blue`, `Purple`, `Black`, `Yellow`, atau kombinasi `Red/Green` |
| `block_icon` | String? | ✅ | Set origin card ini |
| `type` | String? | ✅ | Tags seperti `Straw Hat Crew/East Blue` |
| `effect` | String? | ✅ | Efek teks kartu |
| `trigger` | String? | ✅ | Trigger effect jika ada |
| `card_set` | String? | ✅ | Set code milik kartu ini |
| `card_image_url` | String | ❌ | URL gambar kartu dari server resmi |

### 4.2 `sets_index.json` — Set Schema

```json
{
  "OP-01": {
    "series_id": "OP",
    "name": "ROMANCE DAWN",
    "type": "Booster",
    "release_date": "2022-12-02",
    "product_page": "https://...",
    "cardlist_url": "https://...",
    "images": {
      "box_image": "https://...",
      "banner_image": "https://...",
      "bg_image": "https://...",
      "cards_folder": "https://..."
    },
    "total_cards": 121,
    "scraped": true
  }
}
```

**Set Type Values:** `Booster`, `Starter`, `Extra Booster`, `Premium Booster`

### 4.3 Deck — Persistence Schema (SharedPreferences)

```json
[
  {
    "id": "1748000000000",
    "name": "My Red Luffy Deck",
    "leader": "OP01-001",
    "cards": {
      "OP01-016": 4,
      "OP01-017": 3,
      "OP02-001": 4
    }
  }
]
```

> ⚠️ `leader` hanya menyimpan `cardId` string. Saat load, `DeckModel.fromJson()` me-resolve `CardModel` dari `_allCardsMap`. Pastikan `getAllCards()` dipanggil sebelum `loadDecks()`.

### 4.4 Tournament — Persistence Schema

```json
{
  "id": "t_1748000000",
  "name": "Weekly Tournament",
  "date": "2026-06-07",
  "maxPlayers": 16,
  "topCutSize": 4,
  "status": 1,
  "currentRound": 3,
  "totalSwissRounds": 4,
  "participants": [
    {
      "id": "p_abc123",
      "playerName": "Danny",
      "deckId": "1748000000000",
      "deckName": "Red Luffy",
      "leaderName": "Monkey.D.Luffy",
      "wins": 2,
      "losses": 1,
      "draws": 0,
      "receivedBye": false
    }
  ],
  "matches": [
    {
      "id": "t_abc_r1_m0",
      "round": 1,
      "isTopCut": false,
      "player1Id": "p_abc123",
      "player2Id": "p_def456",
      "winnerId": "p_abc123",
      "isDraw": false,
      "isBye": false,
      "bracketPosition": null
    }
  ]
}
```

**TournamentStatus enum index:**
| Value | Index |
|-------|-------|
| `registration` | 0 |
| `roundRobin` | 1 |
| `topCut` | 2 |
| `finished` | 3 |

### 4.5 QR Code Payload — Tournament Registration

```
Format internal (sebelum encode):
OPTOURNEY|{playerName}|{deckId}|{deckName}|{leaderId}|{leaderName}

Encode: Base64URL(UTF-8(rawString))
```

**Contoh decode:**
```dart
final data = TournamentQrUtils.decode(qrString);
// Returns: { 'playerName', 'deckId', 'deckName', 'leaderId', 'leaderName' }
```

### 4.6 TestSession — In-Memory Game State (Tidak di-persist)

```
TestSessionModel
├── leader: CardModel
├── drawPile: List<CardModel>      // Main deck
├── hand: List<CardModel>          // Hand kartu pemain
├── lifeCards: List<CardModel>     // Life zone
├── field: List<FieldCard>         // Kartu di battle area
├── trashPile: List<CardModel>     // Trash/graveyard
├── donDeck: List<CardModel>       // 10 DON!! cards
├── donAvailable: int              // DON!! aktif (belum digunakan)
├── donRested: int                 // DON!! sudah dipakai/attached
├── donTotal: int                  // Total DON!! terkumpul
├── turnNumber: int
├── currentPhase: TurnPhase        // refresh/draw/don/main/end
├── actionLog: List<String>        // Max 50 entries
└── isFirstTurn: bool              // First player skip draw

FieldCard
├── card: CardModel
├── isRested: bool
└── attachedDon: int
```

---

## 5. Business Rules

### 5.1 Deck Construction Rules

```
✅ Deck valid jika:
  - Tepat 1 Leader card
  - Tepat 50 kartu di main deck
  - Setiap kartu max 4 copy (base ID — parallel dihitung bersama)
  - Semua kartu main deck harus kompatibel dengan warna Leader
  - Tidak boleh ada Leader lain di main deck

✅ Validasi warna:
  - Leader "Red/Green" → boleh pakai kartu Red, Green, atau Red/Green
  - Kartu dual-color: SEMUA warnanya harus ada di Leader
  - Contoh: Kartu "Red/Blue" TIDAK valid di Leader "Red/Green"
```

### 5.2 Tournament Rules

```
Swiss Pairing:
- Pair berdasarkan standing (points, winRate, wins)
- Hindari rematch jika memungkinkan
- Odd player → BYE (menang otomatis, max 1 BYE per player)
- Points: Win=3, Draw=1, Loss=0

Swiss Rounds Recommendation:
- ≤4 players  → 3 rounds
- ≤8 players  → 4 rounds
- ≤16 players → 5 rounds
- ≤32 players → 6 rounds
- >32 players → 7 rounds

Top Cut:
- Seed 1 vs Seed N, Seed 2 vs Seed N-1 (standard seeding)
- Single elimination
- topCutSize: 4 atau 8 (power of 2)
```

### 5.3 Game Rules (TestSession)

```
Turn Phases (urutan wajib):
1. Refresh Phase  — Un-rest semua kartu, return DON!! yang attached
2. Draw Phase     — Draw 1 kartu (skip first turn going first)
3. DON!! Phase    — Tambah 2 DON!! dari DON deck ke cost area
4. Main Phase     — Play kartu, attach DON!!, attack
5. End Phase      — Pass turn

DON!! System:
- Start dengan 10 DON!! di DON deck
- Setiap turn: +2 DON!! ke cost area (available)
- Play card cost X → X DON!! pindah dari available ke rested
- Attach DON!! ke kartu → boost +1000 power per DON!!
- Refresh phase: semua rested DON!! kembali ke available

Life System:
- Life count = nilai "life" di Leader card (biasanya 4 atau 5)
- Ketika life terkena: kartu teratas life pindah ke tangan (trigger)
- isGameOver = lifeCards.isEmpty
```

---

## 6. Color System

### 6.1 Card Colors

| Color | Hex | Dart |
|-------|-----|------|
| Red | `#E53935` | `Color(0xFFE53935)` |
| Green | `#2E7D32` | `Color(0xFF2E7D32)` |
| Blue | `#1565C0` | `Color(0xFF1565C0)` |
| Purple | `#6A1B9A` | `Color(0xFF6A1B9A)` |
| Black | `#263238` | `Color(0xFF263238)` |
| Yellow | `#FBC02D` | `Color(0xFFFBC02D)` |

### 6.2 App Theme Tokens (AppTheme)

| Token | Value | Penggunaan |
|-------|-------|------------|
| `obsidianBg` | `#0A0F1E` | Background utama app |
| `surfaceBg` | `#0F172A` | AppBar, bottom nav |
| `cardBg` | `#1E293B` | Card containers |
| `accentGold` | `#FFD700` | Primary accent, CTA buttons |
| `textPrimary` | `#F5F5F7` | Teks utama |
| `textSecondary` | `#94A3B8` | Teks sub/placeholder |

---

## 7. Dependencies

| Package | Version | Kegunaan |
|---------|---------|---------|
| `cached_network_image` | ^3.4.1 | Cache gambar kartu dari URL |
| `flutter_cache_manager` | ^3.4.1 | Backend cache manager |
| `shared_preferences` | ^2.2.2 | Persistensi deck & tournament |
| `qr_flutter` | ^4.1.0 | Generate QR code |
| `mobile_scanner` | ^7.2.0 | Scan QR code (kamera) |
| `screenshot` | ^3.0.0 | Screenshot hasil turnamen |
| `share_plus` | ^13.1.0 | Share image/file ke platform lain |
| `path_provider` | ^2.1.5 | Akses direktori file system |

---

## 8. Asset Structure

```
assets/data/
├── sets_index.json              # Registry semua set
├── OP-01/ cards.json            # OP-01: Romance Dawn
├── OP-02/ cards.json
├── ...
├── OP-15/ cards.json
├── EB-01/ cards.json            # Extra Booster
├── EB-02/ cards.json
├── EB-03/ cards.json
├── EB-04/ cards.json
├── PRB-01/ cards.json           # Premium Booster
├── PRB-02/ cards.json
├── ST-01/ cards.json            # Starter Deck
├── ...
└── ST-30/ cards.json
```

> Setiap set baru harus:
> 1. Tambah folder `assets/data/{SET-CODE}/cards.json`
> 2. Update `assets/data/sets_index.json`
> 3. Daftarkan asset di `pubspec.yaml` dalam section `flutter.assets`

---

## 9. Web Platform — CORS Handling

Saat app dijalankan di **Flutter Web**, URL gambar kartu (dari server resmi) perlu di-proxy melalui CORS proxy:

```dart
// CardModel.fromJson() — otomatis dilakukan
if (kIsWeb && rawUrl.isNotEmpty && rawUrl.startsWith('http')) {
  rawUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(rawUrl)}';
}
```

> ⚠️ Proxy `api.allorigins.win` adalah third-party. Jika tidak reliable, ganti dengan proxy sendiri atau mirror gambar ke CDN.

---

## 10. Data Scraping

### 10.1 Scraper Files

| File | Deskripsi |
|------|-----------|
| `onepiece_scraper.py` | Main scraper — scrape kartu dari website resmi OP TCG |
| `batch_scrape.py` | Batch mode — scrape multiple set sekaligus |

### 10.2 Menambah Set Baru

```bash
# 1. Scrape kartu baru
python batch_scrape.py --set ST-31

# 2. Output → output/ST-31/cards.json
# 3. Copy ke assets/data/ST-31/cards.json
# 4. Update assets/data/sets_index.json
# 5. Update pubspec.yaml (tambah asset path)
# 6. flutter pub get
```

---

## 11. Coding Conventions

### 11.1 Dart / Flutter Rules

```dart
// ✅ Model: const constructor jika bisa, immutable preferred
class SetModel {
  final String setCode;  // Gunakan final untuk immutable fields
}

// ✅ Nullable: Gunakan ? untuk field yang bisa null
final String? effect;

// ✅ Singleton service: factory constructor pattern
class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();
}

// ✅ Enum: Gunakan extension untuk display logic
extension TournamentStatusLabel on TournamentStatus {
  String get label { ... }
}

// ✅ Async: Selalu handle error dengan try/catch di service layer
Future<List<CardModel>> getCards(String setCode) async {
  try { ... } catch (e) { print('Error: $e'); return []; }
}

// ✅ Widget: Pisahkan build method jika > 50 baris
Widget _buildHeader() { ... }
Widget _buildCardList() { ... }

// ❌ Hindari: hardcode warna inline di widget
// Gunakan AppTheme.accentGold bukan Color(0xFFFFD700)
```

### 11.2 Naming Conventions

| Jenis | Convention | Contoh |
|-------|-----------|--------|
| File | `snake_case.dart` | `deck_model.dart` |
| Class | `PascalCase` | `DeckModel`, `DataService` |
| Variable/method | `camelCase` | `totalCardCount`, `loadDecks()` |
| Constant | `camelCase` | `AppTheme.accentGold` |
| Enum value | `camelCase` | `TurnPhase.refresh` |
| Asset path | `kebab-case folder` | `assets/data/OP-01/cards.json` |

### 11.3 File Organization Rules

- **1 class utama = 1 file** (kecuali helper class kecil di file sama seperti `TournamentQrUtils`)
- **Screen files** → `lib/screens/` (max nesting 1 level subfolder)
- **Models** → pure Dart, minimal Flutter import (kecuali `CardModel` yang perlu `Color`)
- **Services** → akses data, persistence, NO UI logic
- **Widgets** → reusable UI components, bukan screen-level

---

## 12. Known Limitations & Tech Debt

| Issue | Severity | Keterangan |
|-------|----------|------------|
| No state management lib | Medium | Semua `setState()`. Jika fitur bertambah, refactor ke Riverpod |
| SharedPreferences size limit | Medium | JSON deck/tournament bisa besar, pertimbangkan Hive/Isar |
| No error UI | Low | Error hanya `print()` di service, belum ada UI feedback |
| CORS proxy dependency | Medium | `allorigins.win` bisa down, hanya affects Web platform |
| TestSession tidak persist | Low | Sesi test hilang jika app di-close, by design |
| Preset deck card IDs | Medium | Hardcoded dengan suffix `_r1`, `_p1` — verifikasi saat set baru muncul |

---

## 13. Feature Roadmap (Suggested Next Steps)

### Fase 1 — Stability
- [ ] Tambah error state UI (empty state, retry button)
- [ ] Migrasi storage ke **Hive** atau **Isar** untuk performa & kapasitas lebih baik
- [ ] Unit test untuk `TournamentModel` (pairing logic, standings)
- [ ] Unit test untuk `DeckModel` (validasi warna, card count)

### Fase 2 — Features
- [ ] **Online sync** — Supabase/Firebase untuk tournament sharing
- [ ] **Match history** — Detail log setiap pertandingan
- [ ] **Deck statistics** — Cost curve graph, color distribution
- [ ] **Card wishlist** — Tandai kartu yang ingin dikumpulkan
- [ ] **2-player mode** — TestSession untuk 2 pemain di 1 device

### Fase 3 — Polish
- [ ] **Push notification** — Reminder sesi turnamen
- [ ] **Export deck** — PDF decklist untuk cetak
- [ ] **Multi-language** — ID/EN toggle untuk nama kartu
- [ ] **Offline image cache** — Pre-download semua gambar satu set

---

## 14. Environment Setup

```bash
# Requirements
Flutter SDK: ^3.11.5
Dart SDK: ^3.11.5

# Install dependencies
flutter pub get

# Run development
flutter run

# Run on specific platform
flutter run -d chrome          # Web
flutter run -d windows         # Windows desktop
flutter run -d android         # Android device/emulator

# Build release
flutter build apk --release    # Android APK
flutter build appbundle        # Android AAB (Play Store)
flutter build windows          # Windows EXE
```

---

## 15. Quick Reference — Key Files

| File | Fungsi Utama |
|------|-------------|
| `lib/main.dart` | Entry point, tema app |
| `lib/theme/app_theme.dart` | Semua color tokens & ThemeData |
| `lib/services/data_service.dart` | **Pusat semua data access** |
| `lib/models/card_model.dart` | Model kartu + color helpers |
| `lib/models/deck_model.dart` | Model deck + validasi |
| `lib/models/tournament_model.dart` | Swiss pairing + Top Cut logic |
| `lib/models/test_session_model.dart` | Game state engine |
| `lib/screens/testing/preset_decks.dart` | Data deck starter bawaan |
| `lib/screens/tournament/deck_qr_screen.dart` | QR encode/decode utils |
| `assets/data/sets_index.json` | Registry semua set yang tersedia |

---

*Last updated: 2026-06-07 | Maintained by: Danny Prihandoko*
