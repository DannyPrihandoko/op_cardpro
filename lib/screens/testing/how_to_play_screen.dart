import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({Key? key}) : super(key: key);

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'HOW TO PLAY',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              labelColor: const Color(0xFFFFD700),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'SETUP'),
                Tab(text: 'TURNS'),
                Tab(text: 'EFFECTS'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSetupTab(),
          _buildTurnsTab(),
          _buildEffectsTab(),
        ],
      ),
    );
  }

  // ─── TAB 1: SETUP ─────────────────────────────────────────────────────────
  Widget _buildSetupTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _sectionHeader('🎮 GAME SETUP', 'How to start a game'),
        const SizedBox(height: 16),

        _setupStep(
          number: '1',
          title: 'Prepare Your Deck',
          description:
              'Shuffle your 50-card main deck and place your Leader card face-up. '
              'Place your DON!! deck (10 cards) to the side.',
          color: const Color(0xFFE53935),
        ),
        _setupStep(
          number: '2',
          title: 'Decide Turn Order',
          description:
              'Decide who goes first (rock-paper-scissors or any method). '
              'The winner chooses to go first or second.',
          color: const Color(0xFF1565C0),
        ),
        _setupStep(
          number: '3',
          title: 'Draw Opening Hand',
          description:
              'Draw 5 cards from the top of your deck. '
              'You may perform a one-time MULLIGAN: shuffle hand back, re-shuffle, and draw 5 new cards.',
          color: const Color(0xFF2E7D32),
        ),
        _setupStep(
          number: '4',
          title: 'Set Life Cards',
          description:
              'Take cards from the top of your deck equal to your Leader\'s Life value '
              '(usually 4-5) and place them face-down in the Life area.',
          color: const Color(0xFF6A1B9A),
        ),
        _setupStep(
          number: '5',
          title: 'Begin Play',
          description:
              'The player going first starts their turn. '
              'Note: The first player does NOT draw during their first Draw Phase.',
          color: const Color(0xFFFFD700),
          isLast: true,
        ),

        const SizedBox(height: 32),
        _sectionHeader('🏆 VICTORY CONDITIONS', 'How to win the game'),
        const SizedBox(height: 16),
        _victoryCard(
          icon: CupertinoIcons.heart_slash,
          title: 'Deplete Life Cards',
          description:
              'Win a battle against your opponent\'s Leader when they have 0 Life cards remaining.',
          color: const Color(0xFFE53935),
        ),
        const SizedBox(height: 12),
        _victoryCard(
          icon: CupertinoIcons.doc_on_doc,
          title: 'Empty Deck',
          description:
              'Your opponent has no cards left in their deck when they need to draw.',
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(height: 32),

        _sectionHeader('🃏 DECK RULES', 'Construction rules'),
        const SizedBox(height: 16),
        _ruleCard('1 Leader card (set aside, not in main deck)'),
        _ruleCard('Exactly 50 cards in main deck'),
        _ruleCard('Max 4 copies of any card (by base card ID)'),
        _ruleCard('All non-Leader cards must match Leader\'s color(s)'),
        _ruleCard('1 DON!! deck with exactly 10 DON!! cards'),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─── TAB 2: TURNS ─────────────────────────────────────────────────────────
  Widget _buildTurnsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _sectionHeader('🔄 TURN STRUCTURE', '5 phases every turn'),
        const SizedBox(height: 20),

        _phaseCard(
          phase: 'Refresh Phase',
          description:
              'Set all your Rested cards back to Active (upright). '
              'All DON!! cards attached to Characters and those in the cost area return as active.',
          color: const Color(0xFFE53935),
          icon: CupertinoIcons.refresh,
          step: 1,
        ),
        _phaseArrow(),
        _phaseCard(
          phase: 'Draw Phase',
          description:
              'Draw 1 card from the top of your deck. '
              '(The player going first skips this on Turn 1.)',
          color: const Color(0xFF2E7D32),
          icon: CupertinoIcons.arrow_up_doc,
          step: 2,
        ),
        _phaseArrow(),
        _phaseCard(
          phase: 'DON!! Phase',
          description:
              'Place 2 DON!! cards from your DON!! deck face-up into your cost area. '
              'These are now available to pay costs and attach to cards.',
          color: const Color(0xFF1565C0),
          icon: CupertinoIcons.bolt_circle,
          step: 3,
        ),
        _phaseArrow(),
        _phaseCard(
          phase: 'Main Phase',
          description:
              'Play Character/Stage/Event cards by paying DON!! costs. '
              'Attach DON!! cards to your Leader or Characters to boost their power. '
              'Attack with your Leader or Characters by Resting them.',
          color: const Color(0xFF6A1B9A),
          icon: CupertinoIcons.bolt,
          step: 4,
        ),
        _phaseArrow(),
        _phaseCard(
          phase: 'End Phase',
          description:
              'All DON!! cards that were used for costs become Rested. '
              'Your turn ends and your opponent begins their turn.',
          color: const Color(0xFFB7860B),
          icon: CupertinoIcons.moon,
          step: 5,
          isLast: true,
        ),

        const SizedBox(height: 32),
        _sectionHeader('⚔️ COMBAT', 'How battles work'),
        const SizedBox(height: 16),
        _combatStep('1', 'Declare Attack',
            'Rest your attacking Leader or Character. Declare the target (opponent\'s Leader or a Rested Character).'),
        _combatStep('2', 'Activate Blockers',
            'Opponent may Rest a [Blocker] card to redirect the attack to it.'),
        _combatStep('3', 'Battle',
            'Compare power. If attacker\'s power ≥ defender\'s power, the defender is K.O.\'d.'),
        _combatStep('4', 'Life Damage',
            'If the Leader is K.O.\'d in battle (i.e., attacker wins vs Leader), the defending player takes 1 Life damage: reveal top Life card to hand.'),
        _combatStep('5', 'Trigger Effects',
            'The revealed Life card\'s [Trigger] effect activates if it has one. '
            'If 0 Life cards remain and damage is dealt, the game is over.', isLast: true),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─── TAB 3: EFFECTS ───────────────────────────────────────────────────────
  Widget _buildEffectsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        _sectionHeader('✨ KEYWORD EFFECTS', 'Common card effects explained'),
        const SizedBox(height: 16),

        _effectCard(
          keyword: '[Rush]',
          color: const Color(0xFFE53935),
          icon: '⚡',
          description:
              'This card can attack on the same turn it is played. '
              'Normally, cards cannot attack until the turn after they are played.',
        ),
        _effectCard(
          keyword: '[Blocker]',
          color: const Color(0xFF1565C0),
          icon: '🛡️',
          description:
              'After your opponent declares an attack, you may Rest this card '
              'to make it the new target of the attack instead.',
        ),
        _effectCard(
          keyword: '[Double Attack]',
          color: const Color(0xFFE53935),
          icon: '⚔️',
          description:
              'This card deals 2 damage instead of 1 when it wins a battle '
              'against the opponent\'s Leader.',
        ),
        _effectCard(
          keyword: '[Banish]',
          color: const Color(0xFF263238),
          icon: '💀',
          description:
              'When this card deals damage, the target Life card is sent to '
              'the trash instead of to the hand. Trigger effects do NOT activate.',
        ),
        _effectCard(
          keyword: '[On Play]',
          color: const Color(0xFF2E7D32),
          icon: '🎯',
          description:
              'This effect triggers immediately when the card is played from hand '
              'to the field. Resolve the effect right away.',
        ),
        _effectCard(
          keyword: '[When Attacking]',
          color: const Color(0xFF6A1B9A),
          icon: '🌀',
          description:
              'This effect activates when this card attacks. '
              'Resolve the effect at the start of the attack declaration.',
        ),
        _effectCard(
          keyword: '[Activate: Main]',
          color: const Color(0xFFB7860B),
          icon: '🔔',
          description:
              'You may activate this effect during your Main Phase at any time. '
              'Usually requires resting the card or meeting other conditions.',
        ),
        _effectCard(
          keyword: '[Once Per Turn]',
          color: const Color(0xFF546E7A),
          icon: '🔁',
          description:
              'This ability can only be used once per turn. '
              'Usually paired with [Activate: Main] effects.',
        ),
        _effectCard(
          keyword: '[Counter]',
          color: const Color(0xFF1565C0),
          icon: '🚫',
          description:
              'Play this Event from hand when your Leader or Character is attacked. '
              'Gives a power boost during that battle. Some have additional effects.',
        ),
        _effectCard(
          keyword: '[Trigger]',
          color: const Color(0xFFFFD700),
          icon: '✨',
          description:
              'When this card is revealed as a Life card (due to taking damage), '
              'you may activate the listed Trigger effect before adding it to your hand.',
        ),
        _effectCard(
          keyword: '[DON!! -X]',
          color: const Color(0xFF1565C0),
          icon: '🔄',
          description:
              'Return X DON!! cards from your field to your DON!! deck to pay '
              'this cost. The returned cards are removed from play temporarily.',
        ),
        _effectCard(
          keyword: '[On K.O.]',
          color: const Color(0xFF6A1B9A),
          icon: '💫',
          description:
              'This effect triggers when this Character is K.O.\'d in battle '
              'or by a card effect and sent to the trash.',
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ─── WIDGETS ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _setupStep({
    required String number,
    required String title,
    required String description,
    required Color color,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      height: 1.5,
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

  Widget _victoryCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleCard(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(CupertinoIcons.checkmark_circle_fill,
              color: Color(0xFFFFD700), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(rule,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _phaseCard({
    required String phase,
    required String description,
    required Color color,
    required IconData icon,
    required int step,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phase,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 6),
                Text(description,
                    style: TextStyle(
                        color: Colors.grey[300], fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _phaseArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
      child: Icon(CupertinoIcons.chevron_down,
          color: const Color(0xFFFFD700).withOpacity(0.5), size: 18),
    );
  }

  Widget _combatStep(String num, String title, String desc,
      {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.4)),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _effectCard({
    required String keyword,
    required Color color,
    required String icon,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    keyword,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(description,
                    style: TextStyle(
                        color: Colors.grey[300], fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
