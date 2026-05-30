import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/deck_model.dart';
import '../../theme/app_theme.dart';

/// Encodes a deck + player name into a compact QR-friendly string.
/// Format: OPTOURNEY|playerName|deckId|deckName|leaderId|leaderName
class TournamentQrUtils {
  static const _prefix = 'OPTOURNEY';

  static String encode({
    required String playerName,
    required String deckId,
    required String deckName,
    required String leaderId,
    required String leaderName,
  }) {
    final raw = '$_prefix|$playerName|$deckId|$deckName|$leaderId|$leaderName';
    return base64Url.encode(utf8.encode(raw));
  }

  static Map<String, String>? decode(String qrData) {
    try {
      final raw = utf8.decode(base64Url.decode(qrData));
      if (!raw.startsWith(_prefix)) return null;
      final parts = raw.split('|');
      if (parts.length < 6) return null;
      return {
        'playerName': parts[1],
        'deckId': parts[2],
        'deckName': parts[3],
        'leaderId': parts[4],
        'leaderName': parts[5],
      };
    } catch (_) {
      return null;
    }
  }
}

/// Screen shown to participants: displays their deck QR code to show owner.
class DeckQrScreen extends StatefulWidget {
  final DeckModel deck;

  const DeckQrScreen({super.key, required this.deck});

  @override
  State<DeckQrScreen> createState() => _DeckQrScreenState();
}

class _DeckQrScreenState extends State<DeckQrScreen> {
  final _nameController = TextEditingController();
  String? _qrData;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your player name first'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() {
      _qrData = TournamentQrUtils.encode(
        playerName: name,
        deckId: widget.deck.id,
        deckName: widget.deck.name,
        leaderId: widget.deck.leader.cardId,
        leaderName: widget.deck.leader.name,
      );
    });
  }

  void _copyQr() {
    if (_qrData == null) return;
    Clipboard.setData(ClipboardData(text: _qrData!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR code data copied to clipboard'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBg,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceBg,
        title: const Text('My Tournament QR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Deck info header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.hammer_fill,
                        color: AppTheme.accentGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.deck.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(
                            '${widget.deck.leader.name} · ${widget.deck.totalCardCount} cards',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Player name input
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('YOUR NAME',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your player name...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.accentGold),
                ),
              ),
              onSubmitted: (_) => _generate(),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.obsidianBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(CupertinoIcons.qrcode, size: 20),
                label: const Text('Generate QR Code',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: _generate,
              ),
            ),

            if (_qrData != null) ...[
              const SizedBox(height: 32),
              // QR Code display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withOpacity(0.25),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                _nameController.text.trim(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.deck.name,
                style: const TextStyle(
                    color: AppTheme.accentGold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                widget.deck.leader.name,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 16),
                label: const Text('Copy Code (for manual entry)'),
                onPressed: _copyQr,
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.info_circle,
                        color: Color(0xFF3B82F6), size: 16),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Show this QR code to the tournament owner to register.',
                        style: TextStyle(
                            color: Color(0xFF3B82F6), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
