import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';

class DetailScreen extends StatelessWidget {
  final CardModel card;

  const DetailScreen({Key? key, required this.card}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardColor = card.getPrimaryColor();
    final gradient = card.getCardGradient();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(card.cardId),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing ${card.name} (${card.cardId})'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Card Image (Left) + Basic Stats Column (Right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Compact Card Image with Hero & Tap-to-Zoom
                  GestureDetector(
                    onTap: () => _showZoomDialog(context),
                    child: Hero(
                      tag: 'card_img_${card.cardId}',
                      child: Container(
                        height: 196,
                        width: 140, // Preserves 1.4 Aspect Ratio
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: cardColor.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: card.cardImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(gradient: gradient),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(gradient: gradient),
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.white, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right: Minimalist details column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card ID & Rarity Tag
                        Row(
                          children: [
                            Text(
                              card.cardId,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cardColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: cardColor.withOpacity(0.4), width: 1),
                              ),
                              child: Text(
                                card.rarity,
                                style: TextStyle(
                                  color: cardColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Card Name
                        Text(
                          card.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Type & Archetype
                        Text(
                          '${card.cardType}${card.type != null ? " • ${card.type}" : ""}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),

                        // Color Indicator
                        if (card.color != null && card.color!.isNotEmpty) ...[
                          Row(
                            children: [
                              ...card.getCardColors().map((col) => Container(
                                margin: const EdgeInsets.only(right: 4),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: col,
                                  shape: BoxShape.circle,
                                ),
                              )),
                              const SizedBox(width: 4),
                              Text(
                                card.color!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Minimalist Stats Wrap
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (card.cost != null && card.cost != '-' && card.cost!.isNotEmpty)
                              _buildMiniBadge(
                                icon: Icons.star_rounded,
                                iconColor: const Color(0xFFFFD700),
                                label: 'Cost',
                                value: card.cost!,
                              ),
                            if (card.life != null && card.life != '-' && card.life!.isNotEmpty)
                              _buildMiniBadge(
                                icon: Icons.favorite_rounded,
                                iconColor: const Color(0xFFEF5350),
                                label: 'Life',
                                value: card.life!,
                              ),
                            if (card.power != null && card.power != '-' && card.power!.isNotEmpty)
                              _buildMiniBadge(
                                icon: Icons.flash_on_rounded,
                                iconColor: const Color(0xFFFF9100),
                                label: 'Power',
                                value: card.power!,
                              ),
                            if (card.counter != null && card.counter != '-' && card.counter!.isNotEmpty && card.counter != '0')
                              _buildMiniBadge(
                                icon: Icons.shield_rounded,
                                iconColor: const Color(0xFF00E676),
                                label: 'Counter',
                                value: card.counter!.startsWith('+') ? card.counter! : '+${card.counter}',
                              ),
                            if (card.attribute != null && card.attribute != '-' && card.attribute!.isNotEmpty)
                              _buildMiniBadge(
                                icon: Icons.workspace_premium_rounded,
                                iconColor: const Color(0xFF29B6F6),
                                label: 'Attr',
                                value: card.attribute!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white38, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Tap card to zoom',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Card Effect section
              if (card.effect != null && card.effect!.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'CARD EFFECT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Premium Slate background
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardColor.withOpacity(0.25), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: cardColor.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: _parseEffectText(card.effect!),
                      style: const TextStyle(
                        color: Color(0xFFECEFF1),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Card Trigger section
              if (card.trigger != null && card.trigger!.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350), // Red accent
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'TRIGGER EFFECT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D161A), // Sleek reddish slate dark color
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.35), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF5350).withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bolt, color: Color(0xFFEF5350), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: _parseEffectText(card.trigger!),
                            style: const TextStyle(
                              color: Color(0xFFECEFF1),
                              fontSize: 15,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Card Set details
              if (card.cardSet != null && card.cardSet!.isNotEmpty) ...[
                const Text(
                  'EXPANSION SET',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.cardSet!,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // TCG Keyword Parser for high-fidelity styled text
  List<InlineSpan> _parseEffectText(String text) {
    final List<InlineSpan> spans = [];
    final RegExp regExp = RegExp(r'\[([^\]]+)\]');
    
    int start = 0;
    for (final RegExpMatch match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      
      final String tag = match.group(0)!; // Includes brackets like [On Play]
      final String tagText = match.group(1)!.toLowerCase();
      
      Color tagColor = const Color(0xFFFFD700); // Default Amber/Gold
      if (tagText.contains('once per turn')) {
        tagColor = const Color(0xFFFF9100); // Orange
      } else if (tagText.contains("opponent's turn") || tagText.contains("your turn")) {
        tagColor = const Color(0xFF29B6F6); // Sky Blue
      } else if (tagText.contains('don!!')) {
        tagColor = const Color(0xFFB388FF); // Soft Violet
      } else if (tagText.contains('blocker') || tagText.contains('rush') || tagText.contains('double attack')) {
        tagColor = const Color(0xFF00E676); // Mint Green
      } else if (tagText.contains('main') || tagText.contains('counter')) {
        tagColor = const Color(0xFFFF5252); // Red
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tagColor.withOpacity(0.6), width: 1),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: tagColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      
      start = match.end;
    }
    
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    
    return spans;
  }

  // Double tap/click to Zoom Overlay
  void _showZoomDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: const Color(0xE6000000),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(10),
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: card.cardImageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 100,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
