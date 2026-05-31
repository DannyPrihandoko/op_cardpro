import '../../models/deck_model.dart';
import '../../models/card_model.dart';

/// Preset starter deck compositions for ST-27, ST-28, ST-29, ST-30.
/// Card counts based on official One Piece TCG starter deck decklists.
/// Each starter deck = 1 Leader + 50 cards.
class PresetDecks {
  /// Returns all 4 latest preset decks as [PresetDeckInfo]
  static List<PresetDeckInfo> getAll() {
    return [
      _st27(),
      _st28(),
      _st29(),
      _st30(),
    ];
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ST-27: Black Marshall.D.Teach
  // Official count: 50 main deck cards
  // ──────────────────────────────────────────────────────────────────────────
  static PresetDeckInfo _st27() {
    return PresetDeckInfo(
      setCode: 'ST-27',
      name: 'Black Marshall.D.Teach',
      theme: 'Trash-Based Control',
      color: 'Black',
      description:
          'A powerful Black control deck centered around Marshall.D.Teach. '
          'Uses trash as a resource with [On K.O.] draw effects and '
          '[Activate: Main] abilities to dominate through card advantage.',
      leaderId: 'OP09-081_p2',
      // Official ST-27 decklist (50 cards total)
      cardCounts: {
        'OP09-083_r1': 4,  // Van Augur x4
        'OP09-086_r1': 4,  // Jesus Burgess x4
        'OP09-088_r1': 4,  // Shiryu x4
        'OP09-089_r1': 4,  // Stronger x4
        'OP09-090_r1': 4,  // Doc Q x4
        'OP09-091_r1': 4,  // Vasco Shot x4
        'OP09-095_r1': 4,  // Laffitte x4
        'OP09-099_r1': 4,  // Fullalead (Stage) x4
        'OP10-084_r1': 2,  // Sanjuan.Wolf x2
        'ST27-001': 4,     // Avalo Pizarro x4
        'ST27-002': 4,     // Catarina Devon x4
        'ST27-003': 2,     // Kuzan x2
        'ST27-004': 4,     // Sanjuan.Wolf x4
        'ST27-005': 2,     // Marshall.D.Teach x2
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ST-28: Green/Yellow Yamato
  // Official count: 50 main deck cards
  // ──────────────────────────────────────────────────────────────────────────
  static PresetDeckInfo _st28() {
    return PresetDeckInfo(
      setCode: 'ST-28',
      name: 'Green/Yellow Yamato',
      theme: 'Wano Aggro',
      color: 'Green/Yellow',
      description:
          'A dual-color Green/Yellow deck built around Yamato as Leader. '
          'Features the Nine Red Scabbards and Wano Kingdom allies for '
          'a well-rounded aggro strategy.',
      leaderId: 'OP06-022_p3',
      cardCounts: {
        'OP06-100_r2': 4,  // Inuarashi x4
        'OP06-103_r1': 4,  // Kawamatsu x4
        'OP06-104_r1': 4,  // Kikunojo x4
        'OP06-109_r1': 4,  // Denjiro x4
        'OP06-110_r2': 4,  // Nekomamushi x4
        'OP06-112_r1': 4,  // Raizo x4
        'OP07-116_p1': 4,  // Blaze Slice (Event) x4
        'OP09-035_r1': 4,  // Portgas.D.Ace x4
        'ST13-016_r1': 4,  // Yamato x4
        'ST28-001': 4,     // Ashura Doji x4
        'ST28-002': 2,     // Izo x2
        'ST28-003': 4,     // Kin'emon x4
        'ST28-004': 2,     // Kouzuki Momonosuke x2
        'ST28-005': 2,     // Yamato x2
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ST-29: EGGHEAD (Yellow Monkey.D.Luffy)
  // Official count: 50 main deck cards (parallel cards are same base card)
  // ──────────────────────────────────────────────────────────────────────────
  static PresetDeckInfo _st29() {
    return PresetDeckInfo(
      setCode: 'ST-29',
      name: 'Egghead - Luffy',
      theme: 'Yellow Trigger Chain',
      color: 'Yellow',
      description:
          'Yellow Monkey.D.Luffy leads the Straw Hat crew through the Egghead arc. '
          'A trigger-heavy deck using Life card activations to generate advantage '
          'and powerful Event cards.',
      leaderId: 'ST29-001',
      cardCounts: {
        'ST29-002': 4,  // Usopp x4
        'ST29-003': 4,  // Kaku x4
        'ST29-004': 4,  // Sanji x4
        'ST29-005': 4,  // Jinbe x4
        'ST29-006': 4,  // Stussy x4
        'ST29-007': 4,  // Tony Tony.Chopper x4
        'ST29-008': 4,  // Nami x4
        'ST29-009': 4,  // Nico Robin x4
        'ST29-010': 2,  // Franky x2
        'ST29-011': 2,  // Brook x2
        'ST29-012': 4,  // Monkey.D.Luffy x4
        'ST29-013': 2,  // Rob Lucci x2
        'ST29-014': 4,  // Roronoa Zoro x4
        'ST29-015': 2,  // Raw Heat Strike x2
        'ST29-016': 2,  // Kizaru!! Event x2
        'ST29-017': 4,  // Iai Death Lion Song x4
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ST-30: Luffy & Ace (Red/Green Starter EX)
  // Official count: 50 main deck cards
  // ──────────────────────────────────────────────────────────────────────────
  static PresetDeckInfo _st30() {
    return PresetDeckInfo(
      setCode: 'ST-30',
      name: 'Luffy & Ace',
      theme: 'Red/Green Rush',
      color: 'Red/Green',
      description:
          'A powerful dual-color Red/Green deck featuring the legendary brothers '
          'Luffy & Ace as co-Leaders. Rush down opponents with Marineford\'s '
          'finest allies and aggressive event support.',
      leaderId: 'ST30-001',
      cardCounts: {
        'ST30-002': 4,  // Inazuma x4
        'ST30-003': 2,  // Edward.Newgate x2
        'ST30-004': 4,  // Emporio.Ivankov x4
        'ST30-005': 2,  // Jozu x2
        'ST30-006': 4,  // Jinbe x4
        'ST30-007': 4,  // Portgas.D.Ace x4
        'ST30-008': 4,  // Marco x4
        'ST30-009': 2,  // LittleOars Jr. x2
        'ST30-010': 4,  // Crocodile x4
        'ST30-011': 4,  // Buggy x4
        'ST30-012': 4,  // Monkey.D.Luffy x4
        'ST30-013': 4,  // Mr.2.Bon.Kurei x4
        'ST30-014': 2,  // Mr.3(Galdino) x2
        'ST30-015': 2,  // "Whitebeard" Event x2
        'ST30-016': 2,  // "Can You Still Fight" Event x2
        'ST30-017': 2,  // "Big Trouble" Event x2
      },
    );
  }
}

/// Metadata about a preset deck
class PresetDeckInfo {
  final String setCode;
  final String name;
  final String theme;
  final String color;
  final String description;
  final String leaderId;

  /// Map of cardId → copy count (must total 50 cards)
  final Map<String, int> cardCounts;

  const PresetDeckInfo({
    required this.setCode,
    required this.name,
    required this.theme,
    required this.color,
    required this.description,
    required this.leaderId,
    required this.cardCounts,
  });

  int get totalCards => cardCounts.values.fold(0, (s, c) => s + c);

  /// Build a DeckModel from this preset using the resolved card map
  DeckModel? toDeckModel(Map<String, CardModel> allCardsMap) {
    final leaderCard = allCardsMap[leaderId];
    if (leaderCard == null) return null;

    final Map<String, int> resolvedCards = {};
    for (final entry in cardCounts.entries) {
      if (allCardsMap.containsKey(entry.key)) {
        resolvedCards[entry.key] = entry.value;
      }
    }

    return DeckModel(
      id: 'preset_$setCode',
      name: name,
      leader: leaderCard,
      cards: resolvedCards,
    );
  }
}
