import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/set_model.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../models/tournament_model.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Cached sets
  List<SetModel> _sets = [];
  // Cached cards by set code
  final Map<String, List<CardModel>> _cardsBySet = {};
  // Cached list of ALL cards across all sets
  List<CardModel> _allCards = [];
  // Map of card ID to CardModel for fast lookups
  final Map<String, CardModel> _allCardsMap = {};

  // Fetch all sets from assets
  Future<List<SetModel>> getSets() async {
    if (_sets.isNotEmpty) return _sets;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/sets_index.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      final List<SetModel> loadedSets = [];
      jsonMap.forEach((key, value) {
        loadedSets.add(SetModel.fromJson(key, value));
      });

      // Sort sets by release date descending
      loadedSets.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
      
      _sets = loadedSets;
      return _sets;
    } catch (e) {
      print('Error loading sets index: $e');
      return [];
    }
  }

  // Fetch all cards for a specific set
  Future<List<CardModel>> getCards(String setCode) async {
    final cleanSetCode = setCode.toUpperCase();
    if (_cardsBySet.containsKey(cleanSetCode)) {
      return _cardsBySet[cleanSetCode]!;
    }

    try {
      final String path = 'assets/data/$cleanSetCode/cards.json';
      final String jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonList = json.decode(jsonString);
      
      final List<CardModel> loadedCards = jsonList
          .map((item) => CardModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Cache the result
      _cardsBySet[cleanSetCode] = loadedCards;
      
      // Update the mapping
      for (final card in loadedCards) {
        _allCardsMap[card.cardId] = card;
      }

      return loadedCards;
    } catch (e) {
      print('Error loading cards for set $cleanSetCode: $e');
      return [];
    }
  }

  // Fetch and cache all cards across all sets in the database
  Future<List<CardModel>> getAllCards() async {
    if (_allCards.isNotEmpty) return _allCards;

    try {
      final sets = await getSets();
      final List<CardModel> mergedCards = [];

      for (final set in sets) {
        final cards = await getCards(set.setCode);
        mergedCards.addAll(cards);
      }

      _allCards = mergedCards;
      return _allCards;
    } catch (e) {
      print('Error loading all cards: $e');
      return [];
    }
  }

  // Fetch all Leader cards in the database
  Future<List<CardModel>> getAllLeaders() async {
    final allCards = await getAllCards();
    return allCards
        .where((card) => card.cardType.toLowerCase() == 'leader')
        .toList();
  }

  // Search and filter cards across loaded sets or in a specific set
  List<CardModel> filterCards({
    required List<CardModel> sourceCards,
    String query = '',
    String typeFilter = 'All',
    String colorFilter = 'All',
    String rarityFilter = 'All',
  }) {
    return sourceCards.where((card) {
      // 1. Search Query
      if (query.isNotEmpty) {
        final cleanQuery = query.toLowerCase();
        final nameMatch = card.name.toLowerCase().contains(cleanQuery);
        final idMatch = card.cardId.toLowerCase().contains(cleanQuery);
        final effectMatch = card.effect?.toLowerCase().contains(cleanQuery) ?? false;
        final typeTagsMatch = card.type?.toLowerCase().contains(cleanQuery) ?? false;
        
        if (!nameMatch && !idMatch && !effectMatch && !typeTagsMatch) {
          return false;
        }
      }

      // 2. Type Filter (Leader, Character, Event, Stage)
      if (typeFilter != 'All') {
        if (card.cardType.toLowerCase() != typeFilter.toLowerCase()) {
          return false;
        }
      }

      // 3. Color Filter (Red, Green, Blue, Purple, Black, Yellow)
      if (colorFilter != 'All') {
        if (card.color == null) return false;
        
        // Multi-colored cards check
        final cardColors = card.color!.split('/').map((c) => c.trim().toLowerCase());
        if (!cardColors.contains(colorFilter.toLowerCase())) {
          return false;
        }
      }

      // 4. Rarity Filter (L, SR, SEC, R, UC, C)
      if (rarityFilter != 'All') {
        if (card.rarity.toUpperCase() != rarityFilter.toUpperCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Save Decks list to SharedPreferences
  Future<void> saveDecks(List<DeckModel> decks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = decks.map((deck) => deck.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString('op_cardpro_decks', jsonString);
    } catch (e) {
      print('Error saving decks: $e');
    }
  }

  // Load Decks list from SharedPreferences
  Future<List<DeckModel>> loadDecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('op_cardpro_decks');
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      // Ensure all cards are loaded so we can resolve the Leader CardModels correctly
      await getAllCards();

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => DeckModel.fromJson(item as Map<String, dynamic>, _allCardsMap))
          .toList();
    } catch (e) {
      print('Error loading decks: $e');
      return [];
    }
  }

  // ── Tournament persistence ───────────────────────────────────────────────────

  Future<void> saveTournaments(List<TournamentModel> tournaments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tournaments.map((t) => t.toJson()).toList();
      await prefs.setString('op_cardpro_tournaments', json.encode(jsonList));
    } catch (e) {
      print('Error saving tournaments: $e');
    }
  }

  Future<List<TournamentModel>> loadTournaments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('op_cardpro_tournaments');
      if (raw == null || raw.isEmpty) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((item) =>
              TournamentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading tournaments: $e');
      return [];
    }
  }

  // Track which tournaments this device created (owner/admin)
  Future<Set<String>> getOwnedTournamentIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('op_cardpro_owned_tournaments') ?? [];
    return Set<String>.from(list);
  }

  Future<void> addOwnedTournamentId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final owned = await getOwnedTournamentIds();
    owned.add(id);
    await prefs.setStringList(
        'op_cardpro_owned_tournaments', owned.toList());
  }
}
