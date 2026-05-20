import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/set_model.dart';
import '../models/card_model.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Cached sets
  List<SetModel> _sets = [];
  // Cached cards by set code
  final Map<String, List<CardModel>> _cardsBySet = {};

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
      return loadedCards;
    } catch (e) {
      print('Error loading cards for set $cleanSetCode: $e');
      return [];
    }
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
}
