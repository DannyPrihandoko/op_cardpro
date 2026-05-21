import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CardModel {
  final String cardId;
  final String name;
  final String rarity;
  final String cardType; // e.g. "Leader", "Character", "Event", "Stage"
  final String? cost;
  final String? life;
  final String? attribute;
  final String? power;
  final String? counter;
  final String? color; // e.g. "Red", "Red/Green"
  final String? blockIcon;
  final String? type; // e.g. "East Blue/Krieg Pirates"
  final String? effect;
  final String? trigger;
  final String? cardSet;
  final String cardImageUrl;

  CardModel({
    required this.cardId,
    required this.name,
    required this.rarity,
    required this.cardType,
    this.cost,
    this.life,
    this.attribute,
    this.power,
    this.counter,
    this.color,
    this.blockIcon,
    this.type,
    this.effect,
    this.trigger,
    this.cardSet,
    required this.cardImageUrl,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    String rawUrl = json['card_image_url'] ?? '';
    // Fix CORS issue when running on Flutter Web (Chrome/Edge)
    if (kIsWeb && rawUrl.isNotEmpty && rawUrl.startsWith('http')) {
      rawUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(rawUrl)}';
    }

    return CardModel(
      cardId: json['card_id'] ?? '',
      name: json['name'] ?? '',
      rarity: json['rarity'] ?? '',
      cardType: json['card_type'] ?? '',
      cost: json['cost'],
      life: json['life'],
      attribute: json['attribute'],
      power: json['power'],
      counter: json['counter'],
      color: json['color'],
      blockIcon: json['block_icon'],
      type: json['type'],
      effect: json['effect'],
      trigger: json['trigger'],
      cardSet: json['card_set'],
      cardImageUrl: rawUrl,
    );
  }

  // Returns a list of colors matching this card
  List<Color> getCardColors() {
    if (color == null || color!.isEmpty) {
      return [Colors.grey];
    }
    
    final splitColors = color!.split('/');
    final List<Color> result = [];
    
    for (var col in splitColors) {
      col = col.trim().toLowerCase();
      if (col.contains('red')) {
        result.add(const Color(0xFFE53935)); // Crimson Red
      } else if (col.contains('green')) {
        result.add(const Color(0xFF2E7D32)); // Forest Green
      } else if (col.contains('blue')) {
        result.add(const Color(0xFF1565C0)); // Deep Blue
      } else if (col.contains('purple')) {
        result.add(const Color(0xFF6A1B9A)); // Rich Purple
      } else if (col.contains('black')) {
        result.add(const Color(0xFF263238)); // Dark Charcoal / Obsidian
      } else if (col.contains('yellow')) {
        result.add(const Color(0xFFFBC02D)); // Amber Yellow
      } else {
        result.add(Colors.grey);
      }
    }
    
    if (result.isEmpty) result.add(Colors.grey);
    return result;
  }

  // Returns a nice linear gradient representing the card's color(s)
  Gradient getCardGradient() {
    final colors = getCardColors();
    if (colors.length == 1) {
      // Create a nice gradient from the color to a darker shade
      return LinearGradient(
        colors: [colors[0], colors[0].withOpacity(0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  // Returns primary visual color for single color indicator (glow, etc.)
  Color getPrimaryColor() {
    final colors = getCardColors();
    return colors[0];
  }
}
