import 'package:flutter/material.dart';
import 'card_model.dart';

class DeckModel {
  final String id;
  String name;
  final CardModel leader;
  
  // Maps cardId to the count of copies in the deck.
  // E.g., {"OP01-004": 4, "OP01-016": 2}
  final Map<String, int> cards;

  DeckModel({
    required this.id,
    required this.name,
    required this.leader,
    required this.cards,
  });

  // Calculate the total number of cards in the main deck (excluding leader)
  int get totalCardCount {
    return cards.values.fold(0, (sum, count) => sum + count);
  }

  // A deck is valid if it has exactly 50 cards
  bool get isValidCount {
    return totalCardCount == 50;
  }

  // Get count for a specific card ID
  int getCardCount(String cardId) {
    return cards[cardId] ?? 0;
  }

  // Get count for a base card ID (combining parallel versions)
  int getBaseCardCount(String cardId) {
    final baseId = getBaseId(cardId);
    int total = 0;
    cards.forEach((id, count) {
      if (getBaseId(id) == baseId) {
        total += count;
      }
    });
    return total;
  }

  // Static helper to get the base ID (e.g., OP01-001_p1 -> OP01-001)
  static String getBaseId(String cardId) {
    return cardId.split('_')[0];
  }

  // Check if a card is valid to be added to this deck based on Leader colors
  bool isCardValidForLeader(CardModel card) {
    // A deck cannot contain another Leader card in its main deck
    if (card.cardType.toLowerCase() == 'leader') {
      return false;
    }

    final leaderColorStr = leader.color?.toLowerCase() ?? '';
    final cardColorStr = card.color?.toLowerCase() ?? '';

    if (leaderColorStr.isEmpty) return false;
    if (cardColorStr.isEmpty) return false;

    // Split colors by '/' to handle dual-color leaders/cards
    final leaderColors = leaderColorStr.split('/').map((c) => c.trim()).toList();
    final cardColors = cardColorStr.split('/').map((c) => c.trim()).toList();

    // Every color on the card must match at least one color of the Leader
    for (final c in cardColors) {
      if (!leaderColors.contains(c)) {
        return false;
      }
    }
    return true;
  }

  // Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'leader': leader.cardId, // Only store cardId of leader to keep JSON lightweight
      'cards': cards,
    };
  }

  // Deserialize from JSON. Needs a map of all loaded cards to reconstruct the CardModel objects.
  factory DeckModel.fromJson(Map<String, dynamic> json, Map<String, CardModel> allCardsMap) {
    final leaderId = json['leader'] as String;
    final leaderCard = allCardsMap[leaderId] ?? allCardsMap.values.firstWhere(
      (c) => c.cardType.toLowerCase() == 'leader',
      orElse: () => CardModel(
        cardId: leaderId,
        name: 'Unknown Leader',
        rarity: 'L',
        cardType: 'Leader',
        cardImageUrl: '',
      ),
    );

    final rawCards = json['cards'] as Map<String, dynamic>? ?? {};
    final Map<String, int> parsedCards = {};
    rawCards.forEach((key, value) {
      parsedCards[key] = value as int;
    });

    return DeckModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Untitled Deck',
      leader: leaderCard,
      cards: parsedCards,
    );
  }
}
