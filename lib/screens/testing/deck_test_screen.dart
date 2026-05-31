import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/deck_model.dart';
import '../../models/card_model.dart';
import '../../models/test_session_model.dart';
import '../../services/data_service.dart';
import 'playmat_view.dart';

class DeckTestScreen extends StatefulWidget {
  final DeckModel deck;
  const DeckTestScreen({Key? key, required this.deck}) : super(key: key);
  @override
  State<DeckTestScreen> createState() => _DeckTestScreenState();
}

class _DeckTestScreenState extends State<DeckTestScreen>
    with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  late TabController _tabController;
  TestSessionModel? _session;
  bool _isLoading = true;
  bool _isPlaymatMode = true; // High-fidelity visual mate mode by default

  @override
  void initState() {
    super.initState();
    // Force Landscape orientation for testing lab playmat
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _tabController = TabController(length: 3, vsync: this);
    _initSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Restore Portrait orientation when exiting testing lab
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  Future<void> _initSession() async {
    await _dataService.getAllCards();
    final map = _dataService.allCardsMap;
    final List<CardModel> deckCards = [];
    widget.deck.cards.forEach((id, count) {
      final card = map[id];
      if (card != null) {
        for (int i = 0; i < count; i++) deckCards.add(card);
      }
    });
    setState(() {
      _session = TestSessionModel(
        leader: widget.deck.leader,
        deckName: widget.deck.name,
        deckCards: deckCards,
      );
      _isLoading = false;
    });
  }

  void _rebuild() => setState(() {});

  void _playCardWithEffect(CardModel card) {
    final s = _session;
    if (s == null) return;

    final bool isSanji = card.cardId == 'ST29-004';
    final bool isBuggy = card.cardId == 'ST30-011';

    setState(() {
      s.playCard(card);
    });

    if (isSanji || isBuggy) {
      final int peekCount = isSanji ? 4 : 5;
      final lookedAt = s.peekDeck(peekCount);
      if (lookedAt.isEmpty) return;

      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          CardModel? selectedCard;
          return StatefulBuilder(
            builder: (dialogCtx, setDialogState) {
              return CupertinoAlertDialog(
                title: Text(
                  isSanji ? 'Sanji On Play: Straw Hat Search' : 'Buggy On Play: Impel Down/Event Search',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                content: Container(
                  width: 320,
                  height: 160,
                  margin: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      Text(
                        isSanji 
                          ? 'Select up to 1 {Straw Hat Crew} type card to add to hand. Rest go to bottom of deck.'
                          : 'Select up to 1 {Impel Down} type or Event card to add to hand. Rest go to bottom of deck.',
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: lookedAt.length,
                          itemBuilder: (listCtx, index) {
                            final c = lookedAt[index];
                            final bool isStrawHat = c.type?.toLowerCase().contains('straw hat crew') ?? false;
                            final bool isImpelDown = c.type?.toLowerCase().contains('impel down') ?? false;
                            final bool isEvent = c.cardType?.toLowerCase() == 'event';

                            final bool isEligible = isSanji ? isStrawHat : (isImpelDown || isEvent);
                            final bool isSelected = selectedCard == c;

                            return GestureDetector(
                              onTap: isEligible
                                  ? () {
                                      setDialogState(() {
                                        selectedCard = isSelected ? null : c;
                                      });
                                    }
                                  : null,
                              child: Container(
                                width: 56,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFFD700)
                                        : isEligible
                                            ? const Color(0xFF00E676).withOpacity(0.6)
                                            : Colors.white.withOpacity(0.1),
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Opacity(
                                          opacity: isEligible ? 1.0 : 0.35,
                                          child: CachedNetworkImage(
                                            imageUrl: c.cardImageUrl,
                                            httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Container(
                                              color: c.getPrimaryColor().withOpacity(0.3),
                                              child: Center(
                                                child: Text(
                                                  c.name[0],
                                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isEligible)
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(1.5),
                                            decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle),
                                            child: const Icon(Icons.check, color: Colors.black, size: 6),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Pass'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        s.resolveSearchEffect(null, lookedAt);
                      });
                    },
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('Select'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        s.resolveSearchEffect(selectedCard, lookedAt);
                      });
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  void _promptTriggerEffect(CardModel card) {
    final s = _session;
    if (s == null) return;

    if (card.cardId == 'ST29-012') {
      if (s.donRested > 0) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Trigger Luffy Effect?'),
            content: const Text('Give up to 1 rested DON!! card to 1 of your Monkey.D.Luffy cards.'),
            actions: [
              CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
              CupertinoDialogAction(
                child: const Text('Activate'),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    s.addEffectLog(card.name, 'Gave 1 rested DON!! to a Monkey.D.Luffy card.');
                  });
                },
              ),
            ],
          ),
        );
        return;
      }
    }

    final textController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Trigger ${card.name} Effect'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              card.effect ?? 'No standard effect text.',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: textController,
              placeholder: 'Add extra effect details (optional)',
              style: const TextStyle(color: Colors.white, fontSize: 13),
              placeholderStyle: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(
            child: const Text('Trigger & Log'),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                final detail = textController.text.trim().isNotEmpty 
                    ? textController.text.trim() 
                    : 'Activated card effect.';
                s.addEffectLog(card.name, detail);
              });
            },
          ),
        ],
      ),
    );
  }

  Color get _phaseColor {
    switch (_session!.currentPhase) {
      case TurnPhase.refresh: return const Color(0xFFE53935);
      case TurnPhase.draw: return const Color(0xFF2E7D32);
      case TurnPhase.don: return const Color(0xFF1565C0);
      case TurnPhase.main: return const Color(0xFF6A1B9A);
      case TurnPhase.end: return const Color(0xFFB7860B);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F1E),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
      );
    }
    final s = _session!;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: _buildAppBar(s),
      body: !s.gameStarted ? _buildSetupView(s) : _buildGameView(s),
    );
  }

  AppBar _buildAppBar(TestSessionModel s) {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(s.deckName,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      actions: [
        if (s.gameStarted) ...[
          IconButton(
            icon: Icon(_isPlaymatMode ? CupertinoIcons.list_bullet : CupertinoIcons.gamecontroller, color: Colors.white),
            onPressed: () => setState(() => _isPlaymatMode = !_isPlaymatMode),
            tooltip: _isPlaymatMode ? 'Switch to List View' : 'Switch to Playmat View',
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: Color(0xFFFFD700)),
            onPressed: () => showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: const Text('Restart Game?'),
                content: const Text('This will reset all game state.'),
                actions: [
                  CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text('Restart'),
                    onPressed: () {
                      Navigator.pop(context);
                      _initSession();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── SETUP VIEW ────────────────────────────────────────────────────────────
  Widget _buildSetupView(TestSessionModel s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100, height: 140,
                child: CachedNetworkImage(
                  imageUrl: s.leader.cardImageUrl,
                  httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: s.leader.getPrimaryColor(),
                    child: const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.leader.name,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${s.deckName} • ${s.drawPile.length} cards ready',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 32),
            _ctaButton('🎮  Start Game', const Color(0xFFFFD700), Colors.black, () {
              setState(() { s.setupGame(); });
            }),
          ],
        ),
      ),
    );
  }

  // ── GAME VIEW ─────────────────────────────────────────────────────────────
  Widget _buildGameView(TestSessionModel s) {
    if (_isPlaymatMode) {
      return Column(
        children: [
          _buildPhaseBar(s),
          Expanded(
            child: PlaymatView(
              session: s,
              onStateChanged: _rebuild,
              onPlayCard: _playCardWithEffect,
            ),
          ),
          _buildPhaseActions(s),
        ],
      );
    }

    return Column(
      children: [
        _buildStatusBar(s),
        _buildPhaseBar(s),
        Expanded(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                  ),
                  labelColor: const Color(0xFFFFD700),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: 'HAND (${s.handCount})'),
                    Tab(text: 'FIELD (${s.field.length})'),
                    Tab(text: 'LOG'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHandTab(s),
                    _buildFieldTab(s),
                    _buildLogTab(s),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildPhaseActions(s),
      ],
    );
  }

  Widget _buildStatusBar(TestSessionModel s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statChip('❤️', '${s.lifeCount}', 'Life'),
          _statChip('📚', '${s.deckCount}', 'Deck'),
          _statChip('🗑️', '${s.trashPile.length}', 'Trash'),
          _statChip('⚡', '${s.donAvailable}/${s.donTotal}', 'DON!!'),
          _statChip('🔄', '${s.donDeckCount}', 'DON Deck'),
        ],
      ),
    );
  }

  Widget _statChip(String icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9)),
      ],
    );
  }

  Widget _buildPhaseBar(TestSessionModel s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _phaseColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _phaseColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _phaseColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Turn ${s.turnNumber}  •  ${s.currentPhase.displayName}',
              style: TextStyle(color: _phaseColor, fontSize: 12, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (s.hasMulliganed)
            const Text('Mulliganed', style: TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  // ── HAND TAB ──────────────────────────────────────────────────────────────
  Widget _buildHandTab(TestSessionModel s) {
    if (s.hand.isEmpty) {
      return Center(child: Text('Hand is empty', style: TextStyle(color: Colors.grey[500])));
    }
    return Column(
      children: [
        if (!s.hasMulliganed && s.turnNumber == 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: _ctaButton('🔀  Mulligan (Redraw 5)', const Color(0xFF1E3A5F), const Color(0xFF90CAF9), () {
              setState(() { s.mulligan(); });
            }),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.65,
            ),
            itemCount: s.hand.length,
            itemBuilder: (ctx, i) => _HandCardTile(
              card: s.hand[i],
              onPlay: s.currentPhase == TurnPhase.main
                  ? () => _playCardWithEffect(s.hand[i])
                  : null,
              onDiscard: () => setState(() { s.discardFromHand(s.hand[i]); }),
            ),
          ),
        ),
      ],
    );
  }

  // ── FIELD TAB ─────────────────────────────────────────────────────────────
  Widget _buildFieldTab(TestSessionModel s) {
    if (s.field.isEmpty) {
      return Center(child: Text('No cards on field', style: TextStyle(color: Colors.grey[500])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: s.field.length,
      itemBuilder: (ctx, i) {
        final fc = s.field[i];
        return _FieldCardTile(
          fc: fc,
          onAttackDon: s.currentPhase == TurnPhase.main && s.donAvailable > 0
              ? () => setState(() { s.attachDon(fc, 1); })
              : null,
          onKO: () => setState(() { s.koCharacter(fc); }),
          onRest: () => setState(() { fc.isRested = !fc.isRested; }),
          onAttack: () => setState(() { s.attack(fc.card.name, fc.effectivePower); }),
          onEffect: () => _promptTriggerEffect(fc.card),
        );
      },
    );
  }

  // ── LOG TAB ───────────────────────────────────────────────────────────────
  Widget _buildLogTab(TestSessionModel s) {
    if (s.actionLog.isEmpty) {
      return Center(child: Text('No actions yet', style: TextStyle(color: Colors.grey[500])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: s.actionLog.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(s.actionLog[i],
              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4)),
        ),
      ),
    );
  }

  // ── PHASE ACTION BUTTONS ──────────────────────────────────────────────────
  Widget _buildPhaseActions(TestSessionModel s) {
    String btnLabel;
    VoidCallback onPressed;
    Color btnColor = _phaseColor;
    switch (s.currentPhase) {
      case TurnPhase.refresh:
        btnLabel = '🔄  Do Refresh Phase';
        onPressed = () => setState(() { s.doRefreshPhase(); });
        break;
      case TurnPhase.draw:
        btnLabel = '📤  Do Draw Phase';
        onPressed = () => setState(() { s.doDrawPhase(); });
        break;
      case TurnPhase.don:
        btnLabel = '⚡  Do DON!! Phase (+2)';
        onPressed = () => setState(() { s.doDonPhase(); });
        break;
      case TurnPhase.main:
        btnLabel = '✅  End Main Phase';
        onPressed = () => setState(() { s.doEndPhase(); });
        btnColor = const Color(0xFFB7860B);
        break;
      case TurnPhase.end:
        btnLabel = '➡️  Next Turn';
        onPressed = () => setState(() { s.doRefreshPhase(); _tabController.animateTo(0); });
        break;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onPressed,
          child: Text(btnLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _ctaButton(String label, Color bg, Color fg, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

// ── HAND CARD TILE ─────────────────────────────────────────────────────────
class _HandCardTile extends StatelessWidget {
  final CardModel card;
  final VoidCallback? onPlay;
  final VoidCallback onDiscard;
  const _HandCardTile({required this.card, this.onPlay, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    final color = card.getPrimaryColor();
    return GestureDetector(
      onLongPress: () => _showCardMenu(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: card.cardImageUrl,
                  httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: color.withOpacity(0.3),
                    child: Center(child: Text(card.name[0],
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              if (card.cost != null)
                Positioned(
                  top: 4, left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                    child: Text(card.cost!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.black.withOpacity(0.7),
                  child: Text(card.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(card.name),
        message: Text('Cost: ${card.cost ?? "-"}  |  ${card.cardType}  |  Power: ${card.power ?? "-"}'),
        actions: [
          if (onPlay != null)
            CupertinoActionSheetAction(
              onPressed: () { Navigator.pop(context); onPlay!(); },
              child: const Text('▶️  Play Card'),
            ),
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); onDiscard(); },
            isDestructiveAction: true,
            child: const Text('🗑️  Discard'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ── FIELD CARD TILE ────────────────────────────────────────────────────────
class _FieldCardTile extends StatelessWidget {
  final FieldCard fc;
  final VoidCallback? onAttackDon;
  final VoidCallback onKO;
  final VoidCallback onRest;
  final VoidCallback onAttack;
  final VoidCallback? onEffect;
  const _FieldCardTile({
    required this.fc,
    this.onAttackDon,
    required this.onKO,
    required this.onRest,
    required this.onAttack,
    this.onEffect,
  });

  @override
  Widget build(BuildContext context) {
    final color = fc.card.getPrimaryColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fc.isRested ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fc.isRested ? Colors.grey.withOpacity(0.3) : color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44, height: 60,
            child: RotatedBox(
              quarterTurns: fc.isRested ? 1 : 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: fc.card.cardImageUrl,
                  httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fc.card.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Power: ${fc.effectivePower} ${fc.attachedDon > 0 ? "(+${fc.attachedDon} DON!!)" : ""}',
                    style: TextStyle(color: color, fontSize: 11)),
                const SizedBox(height: 2),
                if (fc.card.effect != null)
                  Text(fc.card.effect!, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 10, height: 1.3)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _iconBtn(CupertinoIcons.arrow_turn_down_right, Colors.blue, onRest, 'Rest'),
                  const SizedBox(width: 6),
                  _iconBtn(CupertinoIcons.bolt, Colors.amber, onAttack, 'Attack'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (onEffect != null) ...[
                    _iconBtn(CupertinoIcons.star, Colors.teal, onEffect!, 'Effect'),
                    const SizedBox(width: 6),
                  ],
                  if (onAttackDon != null) ...[
                    _iconBtn(CupertinoIcons.plus_circle, Colors.purple, onAttackDon!, 'DON!!'),
                    const SizedBox(width: 6),
                  ],
                  _iconBtn(CupertinoIcons.trash, Colors.red, onKO, 'K.O.'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      ),
    );
  }
}
