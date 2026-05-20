import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class DeckBuilderScreen extends StatefulWidget {
  const DeckBuilderScreen({Key? key}) : super(key: key);

  @override
  State<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen> {
  // Mock deck list matching One Piece TCG meta
  final List<Map<String, dynamic>> _mockDecks = [
    {
      'name': 'Zoro Rush Aggro',
      'leaderName': 'Edward Newgate / Zoro',
      'cardCount': 50,
      'colors': [const Color(0xFFE53935)], // Red
      'winRate': '68%',
      'matches': 34,
      'tag': 'Aggro',
      'icon': CupertinoIcons.flame_fill,
    },
    {
      'name': 'Trafalgar Law Room',
      'leaderName': 'Trafalgar Law OP01-047',
      'cardCount': 50,
      'colors': [const Color(0xFFE53935), const Color(0xFF2E7D32)], // Red/Green
      'winRate': '62%',
      'matches': 45,
      'tag': 'Midrange',
      'icon': CupertinoIcons.arrow_right_arrow_left_circle_fill,
    },
    {
      'name': 'Eustass Kid Control',
      'leaderName': 'Eustass "Captain" Kid',
      'cardCount': 48,
      'colors': [const Color(0xFF2E7D32)], // Green
      'winRate': '55%',
      'matches': 20,
      'tag': 'Control',
      'icon': CupertinoIcons.shield_fill,
    },
  ];

  void _showCreateDeckDialog() {
    String tempDeckName = '';
    String selectedLeader = 'Monkey D. Luffy';
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Create New Deck',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          content: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Enter deck name and choose a starting leader to build your One Piece custom deck.',
                style: TextStyle(fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                placeholder: 'e.g. Kaido Purple Ramp',
                placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
                style: const TextStyle(color: CupertinoColors.white),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                onChanged: (value) {
                  tempDeckName = value;
                },
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel', style: TextStyle(color: CupertinoColors.destructiveRed)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: const Text('Create', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              onPressed: () {
                if (tempDeckName.trim().isNotEmpty) {
                  setState(() {
                    _mockDecks.insert(0, {
                      'name': tempDeckName,
                      'leaderName': selectedLeader,
                      'cardCount': 0,
                      'colors': [const Color(0xFF6A1B9A)], // Default Purple for Custom
                      'winRate': 'N/A',
                      'matches': 0,
                      'tag': 'Custom',
                      'icon': CupertinoIcons.hammer_fill,
                    });
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deck "$tempDeckName" created! Time to add cards. 🏴‍☠️'),
                      backgroundColor: const Color(0xFFFFD700),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: Colors.black,
                        onPressed: () {},
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E), // AppTheme obsidianBg
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Area
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'DECK CREATOR',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Build Deck',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    // Glassmorphic create deck action
                    GestureDetector(
                      onTap: _showCreateDeckDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.add,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  'Manage, refine, and compile your custom 50-card One Piece tournament decks with optimal curves.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ),

            // Main CTA - Big premium card for creating deck
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GestureDetector(
                  onTap: _showCreateDeckDialog,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1E293B),
                          const Color(0xFF0F172A).withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.hammer,
                            color: Color(0xFFFFD700),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Initialize New Deck',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Combine 1 Leader and exactly 50 cards from verified sets.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Mock Decks section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'YOUR REGISTERED DECKS',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '${_mockDecks.length} TOTAL',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Decks List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final deck = _mockDecks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _DeckListItem(deck: deck),
                    );
                  },
                  childCount: _mockDecks.length,
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _DeckListItem extends StatelessWidget {
  final Map<String, dynamic> deck;

  const _DeckListItem({Key? key, required this.deck}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = deck['colors'];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // Placeholder action for opening deck details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening details for "${deck['name']}"... 🃏'),
                duration: const Duration(seconds: 1),
                backgroundColor: const Color(0xFF0F172A),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                // Deck Color Palette Indicator Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    deck['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 18),

                // Deck Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag & Stats
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              deck['tag'] as String,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.emoji_events_rounded, size: 12, color: const Color(0xFFFFD700).withOpacity(0.8)),
                          const SizedBox(width: 3),
                          Text(
                            'WR: ${deck['winRate']}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Deck Name
                      Text(
                        deck['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Leader Info
                      Text(
                        'Leader: ${deck['leaderName']}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Card Count Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: deck['cardCount'] == 50
                            ? const Color(0xFF2E7D32).withOpacity(0.2)
                            : const Color(0xFFFFD700).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: deck['cardCount'] == 50
                              ? const Color(0xFF81C784).withOpacity(0.4)
                              : const Color(0xFFFFD700).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${deck['cardCount']}/50',
                        style: TextStyle(
                          color: deck['cardCount'] == 50
                              ? const Color(0xFF81C784)
                              : const Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${deck['matches']} matches',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
