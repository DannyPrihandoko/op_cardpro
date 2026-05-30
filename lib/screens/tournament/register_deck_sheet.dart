import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/deck_model.dart';
import '../../theme/app_theme.dart';

class RegisterDeckSheet extends StatefulWidget {
  final List<DeckModel> decks;
  final String playerName;

  const RegisterDeckSheet({
    super.key,
    required this.decks,
    required this.playerName,
  });

  @override
  State<RegisterDeckSheet> createState() => _RegisterDeckSheetState();
}

class _RegisterDeckSheetState extends State<RegisterDeckSheet> {
  late final TextEditingController _nameController;
  DeckModel? _selectedDeck;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playerName);
    if (widget.decks.isNotEmpty) _selectedDeck = widget.decks.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showAlert('Name Required', 'Please enter your player name.');
      return;
    }
    if (_selectedDeck == null) {
      _showAlert('Deck Required', 'Please select a deck to register.');
      return;
    }
    Navigator.pop(context, {
      'playerName': name,
      'deckId': _selectedDeck!.id,
      'deckName': _selectedDeck!.name,
      'leaderName': '${_selectedDeck!.leader.name} (${_selectedDeck!.leader.cardId})',
    });
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.obsidianBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.square_stack_fill,
                      color: Color(0xFF3B82F6), size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Register Deck',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(color: Color(0x1AFFFFFF), height: 24),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PLAYER NAME',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _nameController,
                    placeholder: 'Your name...',
                    placeholderStyle:
                        const TextStyle(color: AppTheme.textSecondary),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  const SizedBox(height: 20),
                  const Text('SELECT DECK',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  if (widget.decks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.exclamationmark_circle,
                              color: AppTheme.textSecondary, size: 18),
                          SizedBox(width: 12),
                          Text(
                            'No decks found. Build a deck first.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ...widget.decks.map((deck) {
                      final isSelected = _selectedDeck?.id == deck.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDeck = deck),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.accentGold.withOpacity(0.1)
                                : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.accentGold
                                  : Colors.white.withOpacity(0.08),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(CupertinoIcons.hammer_fill,
                                    color: AppTheme.accentGold, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(deck.name,
                                        style: TextStyle(
                                            color: isSelected
                                                ? AppTheme.accentGold
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${deck.leader.name} · ${deck.totalCardCount} cards',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(CupertinoIcons.checkmark_circle_fill,
                                    color: AppTheme.accentGold, size: 22),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: widget.decks.isEmpty
                          ? AppTheme.cardBg
                          : AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: widget.decks.isEmpty ? null : _submit,
                      child: Text(
                        'Register',
                        style: TextStyle(
                            color: widget.decks.isEmpty
                                ? AppTheme.textSecondary
                                : AppTheme.obsidianBg,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
