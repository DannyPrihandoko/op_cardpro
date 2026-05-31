import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/card_model.dart';
import '../../models/test_session_model.dart';

class PlaymatView extends StatefulWidget {
  final TestSessionModel session;
  final VoidCallback onStateChanged;
  final void Function(CardModel)? onPlayCard;

  const PlaymatView({
    Key? key,
    required this.session,
    required this.onStateChanged,
    this.onPlayCard,
  }) : super(key: key);

  @override
  State<PlaymatView> createState() => _PlaymatViewState();
}

class _PlaymatViewState extends State<PlaymatView> {
  // Local card detail sheet helper
  void _showCardDetails(CardModel card) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        message: Text(
          'Cost: ${card.cost ?? "-"}  |  Type: ${card.cardType}  |  Power: ${card.power ?? "-"}\n\n'
          'Effect: ${card.effect ?? "No effect"}\n'
          'Trigger: ${card.trigger ?? "No trigger"}',
          textAlign: TextAlign.left,
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Interactive options for played field cards
  void _showFieldCardOptions(FieldCard fc) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(fc.card.name),
        message: Text('Power: ${fc.effectivePower} (${fc.card.power ?? "0"} base + ${fc.attachedDon * 1000} DON!!)\nStatus: ${fc.isRested ? "Rested" : "Active"}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                fc.isRested = !fc.isRested;
              });
              widget.onStateChanged();
            },
            child: Text(fc.isRested ? '🔄  Set Active' : '↪️  Rest Card'),
          ),
          if (widget.session.donAvailable > 0 && widget.session.currentPhase == TurnPhase.main)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  widget.session.attachDon(fc, 1);
                });
                widget.onStateChanged();
              },
              child: const Text('⚡  Attach 1 DON!! (+1000 POW)'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _promptTriggerEffect(fc.card);
            },
            child: const Text('🌟  Trigger Effect / Skill'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                widget.session.koCharacter(fc);
              });
              widget.onStateChanged();
            },
            isDestructiveAction: true,
            child: const Text('🗑️  K.O. / Send to Trash'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // Prompt the user to enter/log custom or automated effects
  void _promptTriggerEffect(CardModel card) {
    // Check if it's ST29-012 Luffy
    if (card.cardId == 'ST29-012') {
      if (widget.session.donRested > 0) {
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
                    // Automate Luffy effect by logging it
                    widget.session.addEffectLog(card.name, 'Gave 1 rested DON!! to a Monkey.D.Luffy card.');
                  });
                  widget.onStateChanged();
                },
              ),
            ],
          ),
        );
        return;
      }
    }

    // Default trigger logs
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
                widget.session.addEffectLog(card.name, detail);
              });
              widget.onStateChanged();
            },
          ),
        ],
      ),
    );
  }

  // Interactive options for played Leader card
  void _showLeaderOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(widget.session.leader.name),
        message: Text('Leader Card\nPower: ${widget.session.leaderPower + (widget.session.leaderAttachedDon * 1000)} (${widget.session.leaderPower} base + ${widget.session.leaderAttachedDon * 1000} DON!!)\nStatus: ${widget.session.isLeaderRested ? "Rested" : "Active"}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                widget.session.isLeaderRested = !widget.session.isLeaderRested;
              });
              widget.onStateChanged();
            },
            child: Text(widget.session.isLeaderRested ? '🔄  Set Active' : '↪️  Rest Leader'),
          ),
          if (widget.session.donAvailable > 0 && widget.session.currentPhase == TurnPhase.main)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  widget.session.attachDonToLeader(1);
                });
                widget.onStateChanged();
              },
              child: const Text('⚡  Attach 1 DON!! (+1000 POW)'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _promptTriggerEffect(widget.session.leader);
            },
            child: const Text('🌟  Trigger Leader Effect'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return Container(
      color: const Color(0xFF070A13),
      child: Column(
        children: [
          // ─── PLAYMAT BOARD (TOP 68% OF LANDSCAPE HEIGHT) ──────────────────────────
          Expanded(
            flex: 68,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  // 1. LEFT COLUMN: LIFE PILE & DON!! DECK
                  Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLifeArea(s),
                        _buildDonDeckArea(s),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 2. CENTER COLUMN: CHARACTER AREA (TOP) & LEADER/STAGE/COST (BOTTOM)
                  Expanded(
                    child: Column(
                      children: [
                        // TOP: CHARACTER AREA (5 Horizontal Slots)
                        Expanded(
                          flex: 11,
                          child: _buildCharacterArea(s),
                        ),
                        const SizedBox(height: 6),
                        // BOTTOM: LEADER, STAGE, COST AREA
                        Expanded(
                          flex: 11,
                          child: Row(
                            children: [
                              _buildLeaderArea(s),
                              const SizedBox(width: 6),
                              _buildStageArea(s),
                              const SizedBox(width: 6),
                              Expanded(child: _buildCostArea(s)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. RIGHT COLUMN: MAIN DECK & TRASH PILE
                  Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDeckArea(s),
                        _buildTrashArea(s),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── HAND TRAY (BOTTOM 32% OF LANDSCAPE HEIGHT) ───────────────────────
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
          ),
          Expanded(
            flex: 32,
            child: Container(
              color: const Color(0xFF0A0D18),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HAND (${s.hand.length})',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Drag cards up\nto play them!',
                          style: TextStyle(color: Color(0xFFFFD700), fontSize: 7, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildHandArea(s),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOARD ZONE BUILDERS (LANDSCAPE CONFIGURATION) ───────────────────────

  // 1. LIFE AREA (Left Edge)
  Widget _buildLifeArea(TestSessionModel s) {
    return GestureDetector(
      onTap: () {
        if (s.lifeCards.isNotEmpty) {
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Take Damage?'),
              content: const Text('Draw the top Life card and add it to your hand.'),
              actions: [
                CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Take Damage'),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      s.triggerLife();
                    });
                    widget.onStateChanged();
                  },
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        width: 70,
        height: 85,
        decoration: BoxDecoration(
          color: const Color(0xFF161E35),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: s.lifeCards.isNotEmpty ? const Color(0xFFFF5252).withOpacity(0.5) : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: s.lifeCards.isNotEmpty
              ? [BoxShadow(color: const Color(0xFFFF5252).withOpacity(0.12), blurRadius: 4)]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (s.lifeCards.isNotEmpty) ...[
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFC62828), Color(0xFF5D1212)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'LIFE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Text(
                    '${s.lifeCards.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else
              Center(
                child: Text(
                  'EMPTY',
                  style: TextStyle(color: Colors.grey[600], fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 2. DON!! DECK AREA (Left Edge)
  Widget _buildDonDeckArea(TestSessionModel s) {
    return GestureDetector(
      onTap: () {
        if (s.currentPhase == TurnPhase.don) {
          setState(() {
            s.doDonPhase();
          });
          widget.onStateChanged();
        }
      },
      child: Container(
        width: 70,
        height: 85,
        decoration: BoxDecoration(
          color: const Color(0xFF1A132C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: s.currentPhase == TurnPhase.don && s.donDeck.isNotEmpty
                ? const Color(0xFF9C27B0)
                : Colors.white.withOpacity(0.05),
            width: s.currentPhase == TurnPhase.don ? 2 : 1,
          ),
          boxShadow: s.currentPhase == TurnPhase.don
              ? [BoxShadow(color: const Color(0xFF9C27B0).withOpacity(0.3), blurRadius: 6)]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (s.donDeck.isNotEmpty) ...[
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    color: const Color(0xFF4A148C),
                    child: const Center(
                      child: Text(
                        'DON!!',
                        style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '${s.donDeck.length} LEFT',
                    style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else
              Center(
                child: Text('EMPTY', style: TextStyle(color: Colors.grey[600], fontSize: 8)),
              ),
          ],
        ),
      ),
    );
  }

  // 3. CHARACTER AREA (Top Center - Horizontal slots)
  Widget _buildCharacterArea(TestSessionModel s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0C101D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          final hasCard = index < s.field.length;
          final FieldCard? fc = hasCard ? s.field[index] : null;

          return DragTarget<CardModel>(
            onWillAccept: (card) {
              return card != null &&
                  card.cardType.toLowerCase() == 'character' &&
                  s.currentPhase == TurnPhase.main;
            },
            onAccept: (card) {
              if (widget.onPlayCard != null) {
                widget.onPlayCard!(card);
              } else {
                setState(() {
                  s.playCard(card);
                });
                widget.onStateChanged();
              }
            },
            builder: (ctx, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;

              return DragTarget<String>(
                onWillAccept: (don) => don == 'DON' && hasCard && s.currentPhase == TurnPhase.main,
                onAccept: (don) {
                  if (fc != null) {
                    setState(() {
                      s.attachDon(fc, 1);
                    });
                    widget.onStateChanged();
                  }
                },
                builder: (ctx, donCandidates, rejectedDons) {
                  final isDonHovering = donCandidates.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      if (fc != null) {
                        _showFieldCardOptions(fc);
                      }
                    },
                    onLongPress: () {
                      if (fc != null) _showCardDetails(fc.card);
                    },
                    child: Container(
                      width: 62,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isHovering
                            ? const Color(0xFFFFD700).withOpacity(0.12)
                            : isDonHovering
                                ? const Color(0xFF9C27B0).withOpacity(0.2)
                                : const Color(0xFF13192B),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isHovering
                              ? const Color(0xFFFFD700)
                              : isDonHovering
                                  ? const Color(0xFF9C27B0)
                                  : fc != null
                                      ? fc.card.getPrimaryColor().withOpacity(0.6)
                                      : Colors.white.withOpacity(0.04),
                          width: (isHovering || isDonHovering) ? 1.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (fc != null) ...[
                              Positioned.fill(
                                child: RotatedBox(
                                  quarterTurns: fc.isRested ? 1 : 0,
                                  child: CachedNetworkImage(
                                    imageUrl: fc.card.cardImageUrl,
                                    httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(
                                      color: fc.card.getPrimaryColor().withOpacity(0.3),
                                      child: Center(
                                        child: Text(
                                          fc.card.name[0],
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (fc.attachedDon > 0)
                                Positioned(
                                  top: 3,
                                  left: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9C27B0),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '+${fc.attachedDon}',
                                      style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                                  child: Text(
                                    fc.isRested ? 'RESTED' : '${fc.effectivePower}',
                                    style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ] else
                              Center(
                                child: Icon(
                                  CupertinoIcons.square_grid_2x2,
                                  color: Colors.white.withOpacity(0.03),
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }

  // 4. LEADER CARD AREA (Bottom Center Left)
  Widget _buildLeaderArea(TestSessionModel s) {
    return DragTarget<String>(
      onWillAccept: (don) => don == 'DON' && s.currentPhase == TurnPhase.main,
      onAccept: (don) {
        setState(() {
          s.attachDonToLeader(1);
        });
        widget.onStateChanged();
      },
      builder: (ctx, donCandidates, rejectedDons) {
        final isDonHovering = donCandidates.isNotEmpty;
        final color = s.leader.getPrimaryColor();

        return GestureDetector(
          onTap: () {
            _showLeaderOptions();
          },
          onLongPress: () => _showCardDetails(s.leader),
          child: Container(
            width: 62,
            height: 80,
            decoration: BoxDecoration(
              color: isDonHovering ? const Color(0xFF9C27B0).withOpacity(0.2) : const Color(0xFF13192B),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDonHovering ? const Color(0xFF9C27B0) : color.withOpacity(0.5),
                width: isDonHovering ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.08), blurRadius: 4),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: RotatedBox(
                      quarterTurns: s.isLeaderRested ? 1 : 0,
                      child: CachedNetworkImage(
                        imageUrl: s.leader.cardImageUrl,
                        httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: color.withOpacity(0.3),
                          child: Center(
                            child: Text(
                              s.leader.name[0],
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (s.leaderAttachedDon > 0)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C27B0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '+${s.leaderAttachedDon}',
                          style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                      child: Text(
                        s.isLeaderRested ? 'REST' : '${s.leaderPower + (s.leaderAttachedDon * 1000)}',
                        style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 5. STAGE AREA (Bottom Center Middle)
  Widget _buildStageArea(TestSessionModel s) {
    FieldCard? stageFC;
    for (final fc in s.field) {
      if (fc.card.cardType.toLowerCase() == 'stage') {
        stageFC = fc;
        break;
      }
    }

    return DragTarget<CardModel>(
      onWillAccept: (card) => card != null && card.cardType.toLowerCase() == 'stage' && s.currentPhase == TurnPhase.main,
      onAccept: (card) {
        if (widget.onPlayCard != null) {
          widget.onPlayCard!(card);
        } else {
          setState(() {
            s.playCard(card);
          });
          widget.onStateChanged();
        }
      },
      builder: (ctx, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final currentStage = stageFC;

        return GestureDetector(
          onTap: () {
            if (currentStage != null) {
              setState(() {
                currentStage.isRested = !currentStage.isRested;
              });
              widget.onStateChanged();
            }
          },
          onLongPress: () {
            if (currentStage != null) _showCardDetails(currentStage.card);
          },
          child: Container(
            width: 62,
            height: 80,
            decoration: BoxDecoration(
              color: isHovering ? const Color(0xFFFFD700).withOpacity(0.1) : const Color(0xFF111627),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isHovering
                    ? const Color(0xFFFFD700)
                    : currentStage != null
                        ? const Color(0xFF00E676)
                        : Colors.white.withOpacity(0.04),
                width: isHovering ? 1.5 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (currentStage != null) ...[
                    Positioned.fill(
                      child: RotatedBox(
                        quarterTurns: currentStage.isRested ? 1 : 0,
                        child: CachedNetworkImage(
                          imageUrl: currentStage.card.cardImageUrl,
                          httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            s.koCharacter(currentStage);
                          });
                          widget.onStateChanged();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 8),
                        ),
                      ),
                    ),
                  ] else
                    Center(
                      child: Text(
                        'STAGE',
                        style: TextStyle(color: Colors.white.withOpacity(0.08), fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 6. COST AREA (Bottom Center Right)
  Widget _buildCostArea(TestSessionModel s) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0C101D),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COST AREA (ACTIVE: ${s.donAvailable} | RESTED: ${s.donRested})',
                style: TextStyle(color: Colors.grey[500], fontSize: 7, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              if (s.donAvailable > 0 && s.currentPhase == TurnPhase.main)
                const Text(
                  'DRAG DON!! TO ATTACH',
                  style: TextStyle(color: Color(0xFF9C27B0), fontSize: 6, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: s.donAvailable == 0
                ? Center(
                    child: Text(
                      'No Active DON!!',
                      style: TextStyle(color: Colors.grey[700], fontSize: 8),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(s.donAvailable, (i) {
                        final token = Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF9C27B0).withOpacity(0.15), blurRadius: 2),
                            ],
                          ),
                          child: const Text(
                            'DON!!',
                            style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                          ),
                        );

                        if (s.currentPhase == TurnPhase.main) {
                          return Draggable<String>(
                            data: 'DON',
                            feedback: Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9C27B0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'DON!!',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(opacity: 0.35, child: token),
                            child: token,
                          );
                        }
                        return token;
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 7. DECK AREA (Right Edge)
  Widget _buildDeckArea(TestSessionModel s) {
    return GestureDetector(
      onTap: () {
        setState(() {
          s.doDrawPhase();
        });
        widget.onStateChanged();
      },
      child: Container(
        width: 70,
        height: 85,
        decoration: BoxDecoration(
          color: const Color(0xFF161E35),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: s.deckCount > 0 ? const Color(0xFFFFD700).withOpacity(0.3) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (s.deckCount > 0) ...[
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F2042), Color(0xFF09101E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'DECK',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.15),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                  child: Text(
                    '${s.deckCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else
              Center(
                child: Text('EMPTY', style: TextStyle(color: Colors.grey[600], fontSize: 8)),
              ),
          ],
        ),
      ),
    );
  }

  // 8. TRASH AREA (Right Edge)
  Widget _buildTrashArea(TestSessionModel s) {
    return DragTarget<CardModel>(
      onWillAccept: (card) => card != null,
      onAccept: (card) {
        setState(() {
          s.discardFromHand(card);
        });
        widget.onStateChanged();
      },
      builder: (ctx, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          width: 70,
          height: 85,
          decoration: BoxDecoration(
            color: isHovering ? Colors.red.withOpacity(0.1) : const Color(0xFF16151B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isHovering
                  ? Colors.red
                  : s.trashPile.isNotEmpty
                      ? Colors.grey.withOpacity(0.4)
                      : Colors.white.withOpacity(0.04),
              width: isHovering ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (s.trashPile.isNotEmpty) ...[
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.25,
                      child: CachedNetworkImage(
                        imageUrl: s.trashPile.last.cardImageUrl,
                        httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.trash, color: Colors.white38, size: 14),
                        const SizedBox(height: 2),
                        Text(
                          '${s.trashPile.length} CARDS',
                          style: const TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.trash, color: Colors.white.withOpacity(0.05), size: 14),
                        const SizedBox(height: 2),
                        Text(
                          'TRASH',
                          style: TextStyle(color: Colors.white.withOpacity(0.05), fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── HAND AREA (BOTTOM TRAY) ──────────────────────────────────────────────

  Widget _buildHandArea(TestSessionModel s) {
    if (s.hand.isEmpty) {
      return Center(
        child: Text(
          'Your hand is empty.',
          style: TextStyle(color: Colors.grey[700], fontSize: 9),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: s.hand.length,
      itemBuilder: (ctx, i) {
        final card = s.hand[i];
        final cardWidget = Container(
          width: 58,
          height: 80,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2239),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: card.getPrimaryColor().withOpacity(0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: card.cardImageUrl,
                    httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: card.getPrimaryColor().withOpacity(0.3),
                      child: Center(
                        child: Text(
                          card.name[0],
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                if (card.cost != null)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                      child: Text(
                        card.cost!,
                        style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        return GestureDetector(
          onTap: () => _showCardDetails(card),
          child: Draggable<CardModel>(
            data: card,
            feedback: Material(
              color: Colors.transparent,
              child: Opacity(
                opacity: 0.8,
                child: SizedBox(
                  width: 58,
                  height: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: CachedNetworkImage(
                      imageUrl: card.cardImageUrl,
                      httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.25, child: cardWidget),
            child: cardWidget,
          ),
        );
      },
    );
  }
}
