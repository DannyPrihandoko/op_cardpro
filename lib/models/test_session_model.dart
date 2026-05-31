import 'dart:math';
import 'card_model.dart';

/// Represents the rest/active state of a card on the field
class FieldCard {
  final CardModel card;
  bool isRested;
  int attachedDon; // DON!! cards attached to boost power

  FieldCard({
    required this.card,
    this.isRested = false,
    this.attachedDon = 0,
  });

  int get effectivePower {
    final base = int.tryParse(card.power ?? '0') ?? 0;
    return base + (attachedDon * 1000);
  }
}

/// The 5 turn phases of One Piece TCG
enum TurnPhase {
  refresh,
  draw,
  don,
  main,
  end,
}

extension TurnPhaseExtension on TurnPhase {
  String get displayName {
    switch (this) {
      case TurnPhase.refresh:
        return 'Refresh Phase';
      case TurnPhase.draw:
        return 'Draw Phase';
      case TurnPhase.don:
        return 'DON!! Phase';
      case TurnPhase.main:
        return 'Main Phase';
      case TurnPhase.end:
        return 'End Phase';
    }
  }

  String get description {
    switch (this) {
      case TurnPhase.refresh:
        return 'Set all rested cards as active. Return all given DON!! cards to your cost area.';
      case TurnPhase.draw:
        return 'Draw 1 card from your deck.';
      case TurnPhase.don:
        return 'Place 2 cards from your DON!! deck into your cost area.';
      case TurnPhase.main:
        return 'Play cards from hand, attach DON!!, and attack with your Leader or Characters.';
      case TurnPhase.end:
        return 'Your turn ends and it becomes your opponent\'s turn.';
    }
  }
}

/// Full game state for a solo testing session
class TestSessionModel {
  final CardModel leader;
  final String deckName;
  final String? deckColor;

  // Zones
  List<CardModel> drawPile = [];
  List<CardModel> hand = [];
  List<CardModel> lifeCards = [];
  List<FieldCard> field = [];
  List<CardModel> trashPile = [];
  List<CardModel> donDeck = []; // 10 DON!! cards

  // DON!! state
  int donAvailable = 0; // Active DON!! in cost area (can be used)
  int donRested = 0;    // Rested DON!! (attached to cards or used)
  int donTotal = 0;     // Total DON!! accumulated so far

  // Turn state
  int turnNumber = 0;
  TurnPhase currentPhase = TurnPhase.refresh;
  bool hasMulliganed = false;
  bool gameStarted = false;
  bool isFirstTurn = true; // First player doesn't draw on turn 1

  // Leader specific state
  bool isLeaderRested = false;
  int leaderAttachedDon = 0;

  // Log
  List<String> actionLog = [];

  TestSessionModel({
    required this.leader,
    required this.deckName,
    this.deckColor,
    required List<CardModel> deckCards,
  }) {
    drawPile = List.from(deckCards);
    // Build 10 DON!! placeholder cards
    donDeck = List.generate(10, (i) => _buildDonCard());
  }

  CardModel _buildDonCard() {
    return CardModel(
      cardId: 'DON!!',
      name: 'DON!!',
      rarity: 'DON',
      cardType: 'DON!!',
      cardImageUrl: '',
      color: 'DON',
    );
  }

  /// Setup: shuffle, set life cards, draw opening hand
  void setupGame() {
    _shuffle();
    final lifeCount = int.tryParse(leader.life ?? '4') ?? 4;
    lifeCards = drawPile.take(lifeCount).toList();
    drawPile.removeRange(0, lifeCount.clamp(0, drawPile.length));
    hand = drawPile.take(5).toList();
    drawPile.removeRange(0, 5.clamp(0, drawPile.length));
    gameStarted = true;
    turnNumber = 1;
    currentPhase = TurnPhase.refresh;
    _log('Game started! Drew 5 cards. ${lifeCards.length} Life cards set.');
  }

  /// Mulligan: put hand back, re-shuffle, draw 5 new cards
  void mulligan() {
    if (hasMulliganed) return;
    drawPile.addAll(hand);
    hand = [];
    _shuffle();
    hand = drawPile.take(5).toList();
    drawPile.removeRange(0, 5.clamp(0, drawPile.length));
    hasMulliganed = true;
    _log('Mulligan! Drew a new hand of ${hand.length} cards.');
  }

  // ── PHASE ACTIONS ──────────────────────────────────────────────────────

  /// Refresh Phase: unrest all cards, return attached DON!!
  void doRefreshPhase() {
    int returnedDon = 0;
    for (final fc in field) {
      fc.isRested = false;
      returnedDon += fc.attachedDon;
      fc.attachedDon = 0;
    }
    isLeaderRested = false;
    returnedDon += leaderAttachedDon;
    leaderAttachedDon = 0;

    donAvailable += returnedDon + donRested;
    donRested = 0;
    currentPhase = TurnPhase.draw;
    _log('Refresh Phase: All cards un-rested. ${returnedDon} DON!! returned.');
  }

  /// Attach DON!! to Leader
  bool attachDonToLeader(int amount) {
    if (donAvailable < amount) return false;
    leaderAttachedDon += amount;
    donAvailable -= amount;
    donRested += amount;
    _log('Attached $amount DON!! to Leader ${leader.name} (+${amount * 1000} power).');
    return true;
  }

  /// Draw Phase: draw 1 card (skip on first turn if going first)
  void doDrawPhase() {
    if (!isFirstTurn) {
      _drawCard();
    }
    currentPhase = TurnPhase.don;
    if (isFirstTurn) {
      _log('Draw Phase: Skipped (first turn, going first).');
    } else {
      _log('Draw Phase: Drew 1 card. Hand: ${hand.length} cards.');
    }
  }

  /// DON!! Phase: add 2 DON!! from deck to cost area
  void doDonPhase() {
    if (donDeck.isNotEmpty) {
      final add = min(2, donDeck.length);
      donAvailable += add;
      donTotal += add;
      donDeck.removeRange(0, add);
      _log('DON!! Phase: Added $add DON!! ($donAvailable active, $donTotal total).');
    }
    currentPhase = TurnPhase.main;
  }

  /// End Phase: move to next turn
  void doEndPhase() {
    isFirstTurn = false;
    turnNumber++;
    currentPhase = TurnPhase.refresh;
    _log('--- End of Turn ${turnNumber - 1}. Starting Turn $turnNumber ---');
  }

  // ── MAIN PHASE ACTIONS ─────────────────────────────────────────────────

  /// Play a Character or Stage card from hand
  bool playCard(CardModel card) {
    final cost = int.tryParse(card.cost ?? '0') ?? 0;
    if (donAvailable < cost) {
      _log('Cannot play ${card.name}: insufficient DON!! (need $cost, have $donAvailable).');
      return false;
    }
    if (!hand.contains(card)) return false;

    hand.remove(card);
    donAvailable -= cost;
    donRested += cost;

    if (card.cardType.toLowerCase() == 'character' ||
        card.cardType.toLowerCase() == 'stage') {
      field.add(FieldCard(card: card));
      _log('[On Play] ${card.name} (Cost: $cost) played to field.');
    } else if (card.cardType.toLowerCase() == 'event') {
      trashPile.add(card);
      _log('[Event] ${card.name} used and sent to trash.');
    }
    return true;
  }

  /// Attach DON!! to a field card to power it up
  bool attachDon(FieldCard target, int amount) {
    if (donAvailable < amount) return false;
    target.attachedDon += amount;
    donAvailable -= amount;
    donRested += amount;
    _log('Attached $amount DON!! to ${target.card.name} (+${amount * 1000} power).');
    return true;
  }

  /// Attack with a field character or leader
  void attack(String attackerName, int? attackPower) {
    _log('⚔️ ${attackerName} attacks with ${attackPower ?? 0} power!');
  }

  /// K.O. a character (move to trash)
  void koCharacter(FieldCard fc) {
    field.remove(fc);
    trashPile.add(fc.card);
    _log('${fc.card.name} was K.O.\'d and sent to trash.');
  }

  /// Discard a card from hand to trash
  void discardFromHand(CardModel card) {
    if (hand.contains(card)) {
      hand.remove(card);
      trashPile.add(card);
      _log('Discarded ${card.name} from hand to trash.');
    }
  }

  /// Trigger a life card (when damaged - flip top life to hand)
  CardModel? triggerLife() {
    if (lifeCards.isEmpty) return null;
    final triggered = lifeCards.removeLast();
    hand.add(triggered);
    _log('💥 Life card triggered! ${triggered.name} added to hand. ${lifeCards.length} life remaining.');
    return triggered;
  }

  /// Peek top cards of the deck (for searching effects)
  List<CardModel> peekDeck(int count) {
    return drawPile.take(count).toList();
  }

  /// Resolve search and choice effects
  void resolveSearchEffect(CardModel? chosen, List<CardModel> lookedAt) {
    // Remove lookedAt cards from the top of the deck
    for (final card in lookedAt) {
      drawPile.remove(card);
    }
    if (chosen != null) {
      hand.add(chosen);
      _log('Added ${chosen.name} to hand from search.');
    }
    // Put remaining lookedAt cards back to the bottom of the deck
    for (final card in lookedAt) {
      if (card != chosen) {
        drawPile.add(card);
      }
    }
    _log('Placed remaining ${chosen != null ? lookedAt.length - 1 : lookedAt.length} cards at bottom of deck.');
  }

  /// Log an activated card effect
  void addEffectLog(String cardName, String effectDetail) {
    _log('[Effect] $cardName: $effectDetail');
  }

  // ── HELPERS ────────────────────────────────────────────────────────────

  void _drawCard() {
    if (drawPile.isNotEmpty) {
      hand.add(drawPile.removeAt(0));
    } else {
      _log('⚠️ Deck is empty! Cannot draw.');
    }
  }

  void _shuffle() {
    final rng = Random();
    for (int i = drawPile.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = drawPile[i];
      drawPile[i] = drawPile[j];
      drawPile[j] = tmp;
    }
  }

  void _log(String message) {
    actionLog.insert(0, '[T$turnNumber ${currentPhase.displayName}] $message');
    if (actionLog.length > 50) actionLog.removeLast();
  }

  int get leaderPower => int.tryParse(leader.power ?? '5000') ?? 5000;
  int get lifeCount => lifeCards.length;
  int get deckCount => drawPile.length;
  int get handCount => hand.length;
  bool get isGameOver => lifeCards.isEmpty;
  int get donDeckCount => donDeck.length;
}
