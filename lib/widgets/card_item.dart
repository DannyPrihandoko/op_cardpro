import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';
import '../screens/detail_screen.dart';

class CardItem extends StatefulWidget {
  final CardModel card;
  final bool compact;

  const CardItem({Key? key, required this.card, this.compact = false}) : super(key: key);

  @override
  State<CardItem> createState() => _CardItemState();
}

class _CardItemState extends State<CardItem> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.card.getPrimaryColor();
    final gradient = widget.card.getCardGradient();

    if (widget.compact) {
      return MouseRegion(
        onEnter: (_) => _animController.forward(),
        onExit: (_) => _animController.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTapDown: (_) => _animController.forward(),
            onTapUp: (_) => _animController.reverse(),
            onTapCancel: () => _animController.reverse(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DetailScreen(card: widget.card),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: cardColor.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Hero(
                  tag: 'card_img_${widget.card.cardId}',
                  child: CachedNetworkImage(
                    imageUrl: widget.card.cardImageUrl,
                    httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        gradient: gradient,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        gradient: gradient,
                      ),
                      child: Center(
                        child: Text(
                          widget.card.cardId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => _animController.forward(),
      onExit: (_) => _animController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTapDown: (_) => _animController.forward(),
          onTapUp: (_) => _animController.reverse(),
          onTapCancel: () => _animController.reverse(),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DetailScreen(card: widget.card),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFF16161C),
                child: Stack(
                  children: [
                    // Card Image with high-quality loading & fallback
                    Positioned.fill(
                      bottom: 48,
                      child: Hero(
                        tag: 'card_img_${widget.card.cardId}',
                        child: CachedNetworkImage(
                          imageUrl: widget.card.cardImageUrl,
                          httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: gradient,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: gradient,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image, color: Colors.white70, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  widget.card.cardId,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Floating rarity badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge(
                        text: widget.card.rarity,
                        bgColor: _getRarityColor(widget.card.rarity),
                        textColor: Colors.black,
                        isBold: true,
                      ),
                    ),

                    // Floating Type/Cost details based on card type
                    if (widget.card.cost != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildBadge(
                          text: '★ ${widget.card.cost}',
                          bgColor: const Color(0xFF263238).withOpacity(0.85),
                          textColor: const Color(0xFFFFD700),
                        ),
                      )
                    else if (widget.card.life != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildBadge(
                          text: '❤ ${widget.card.life}',
                          bgColor: const Color(0xFFE53935).withOpacity(0.85),
                          textColor: Colors.white,
                        ),
                      ),

                    // Card Stats Overlay at bottom (Name and Card ID)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 48,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F12),
                          border: Border(
                            top: BorderSide(
                              color: cardColor.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.card.cardId,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  widget.card.cardType,
                                  style: TextStyle(
                                    color: cardColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required Color bgColor,
    required Color textColor,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'L':
        return const Color(0xFFFFD700); // Gold
      case 'SEC':
        return const Color(0xFFE040FB); // Vibrant Purple / Neon
      case 'SR':
        return const Color(0xFFFF9100); // Vibrant Orange
      case 'R':
        return const Color(0xFF2979FF); // Blue
      case 'UC':
        return const Color(0xFF00E676); // Green
      case 'C':
        return Colors.white70; // Gray/White
      default:
        return const Color(0xFFB0BEC5);
    }
  }
}
