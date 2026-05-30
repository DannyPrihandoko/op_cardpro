import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../services/data_service.dart';
import 'deck_editor_screen.dart';
import 'tournament/deck_qr_screen.dart';

class DeckBuilderScreen extends StatefulWidget {
  const DeckBuilderScreen({Key? key}) : super(key: key);

  @override
  State<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen> {
  final DataService _dataService = DataService();
  
  List<DeckModel> _decks = [];
  List<CardModel> _allLeaders = [];
  List<String> _availableSets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load saved decks and all available Leader cards
    final decks = await _dataService.loadDecks();
    final leaders = await _dataService.getAllLeaders();
    final sets = await _dataService.getSets();

    // Sort leaders by set and ID
    leaders.sort((a, b) => a.cardId.compareTo(b.cardId));

    setState(() {
      _decks = decks;
      _allLeaders = leaders;
      _availableSets = sets.map((s) => s.setCode).toList();
      _isLoading = false;
    });
  }

  Future<void> _deleteDeck(DeckModel deck) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Deck'),
          content: Text('Are you sure you want to delete "${deck.name}"? This action cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () async {
                setState(() {
                  _decks.removeWhere((d) => d.id == deck.id);
                });
                await _dataService.saveDecks(_decks);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deck "${deck.name}" deleted.'),
                    backgroundColor: const Color(0xFF1E293B),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String activeFilter, ValueChanged<String> onTap) {
    final isActive = label == activeFilter;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFD700) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD700) : const Color(0xFF334155),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateDeckDialog() {
    if (_allLeaders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leaders database is not loaded yet. Please wait a moment...'),
          backgroundColor: Color(0xFFEF5350),
        ),
      );
      return;
    }

    String tempDeckName = '';
    CardModel selectedLeader = _allLeaders.first;
    String searchQuery = '';
    String selectedSetFilter = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Filter logic
            final filteredLeaders = _allLeaders.where((leader) {
              // Set filter
              if (selectedSetFilter != 'All') {
                final cleanSetFilter = selectedSetFilter.replaceAll('-', '').toUpperCase();
                final cleanLeaderSet = leader.cardId.split('-')[0].toUpperCase();
                if (cleanLeaderSet != cleanSetFilter) {
                  return false;
                }
              }
              // Search query
              if (searchQuery.isNotEmpty) {
                final cleanQuery = searchQuery.toLowerCase();
                final nameMatch = leader.name.toLowerCase().contains(cleanQuery);
                final idMatch = leader.cardId.toLowerCase().contains(cleanQuery);
                if (!nameMatch && !idMatch) {
                  return false;
                }
              }
              return true;
            }).toList();

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modal Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'INITIALIZE NEW DECK',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(CupertinoIcons.clear_circled, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Input Deck Name
                    const Text(
                      'Deck Name',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      placeholder: 'e.g. Zoro Rush Aggro',
                      placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
                      style: const TextStyle(color: CupertinoColors.white),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      onChanged: (value) {
                        tempDeckName = value;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Select Leader Section Title & Count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Leader Card',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${filteredLeaders.length} found',
                          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CupertinoSearchTextField(
                      placeholder: 'Search Leader by name or ID...',
                      style: const TextStyle(color: Colors.white),
                      placeholderStyle: const TextStyle(color: Colors.white38),
                      backgroundColor: const Color(0xFF1E293B),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Set selection chips
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildFilterChip('All', selectedSetFilter, (val) {
                            setModalState(() {
                              selectedSetFilter = val;
                            });
                          }),
                          ..._availableSets.map((setCode) => _buildFilterChip(setCode, selectedSetFilter, (val) {
                            setModalState(() {
                              selectedSetFilter = val;
                            });
                          })),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Scrollable Grid View of leaders
                    Expanded(
                      child: filteredLeaders.isEmpty
                          ? const Center(
                              child: Text(
                                'No leaders found.',
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            )
                          : GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: filteredLeaders.length,
                              itemBuilder: (context, index) {
                                final leader = filteredLeaders[index];
                                final isSelected = selectedLeader.cardId == leader.cardId;
                                final leaderColor = leader.getPrimaryColor();

                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedLeader = leader;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF334155),
                                        width: isSelected ? 2.5 : 1.0,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: CachedNetworkImage(
                                              imageUrl: leader.cardImageUrl,
                                              httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
                                              fit: BoxFit.cover,
                                              placeholder: (c, u) => Container(
                                                color: Colors.black26,
                                                child: const Center(
                                                    child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation(Colors.white30))),
                                              ),
                                              errorWidget: (c, u, e) => Container(
                                                color: leaderColor,
                                                padding: const EdgeInsets.all(8),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      leader.name,
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      leader.cardId,
                                                      style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Set Tag on top-left of image
                                          Positioned(
                                            top: 4,
                                            left: 4,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                leader.cardId.split('-')[0],
                                                style: const TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          // Selected Overlay checkmark
                                          if (isSelected)
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFFD700),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(CupertinoIcons.checkmark_alt,
                                                    size: 14, color: Colors.black),
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
                    const SizedBox(height: 16),

                    // Create CTA
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CupertinoButton(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(12),
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Create Deck',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () async {
                          final name = tempDeckName.trim().isNotEmpty
                              ? tempDeckName.trim()
                              : 'My ${selectedLeader.name} Deck';

                          final newDeck = DeckModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: name,
                            leader: selectedLeader,
                            cards: {},
                          );

                          setState(() {
                            _decks.insert(0, newDeck);
                          });
                          await _dataService.saveDecks(_decks);

                          Navigator.of(context).pop();

                          // Redirect directly to the Deck Editor
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DeckEditorScreen(
                                deck: newDeck,
                                allDecks: _decks,
                                onDeckUpdated: () {
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              )
            : CustomScrollView(
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
                          // Glassmorphic create deck action button
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

                  // Main Big premium CTA card
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

                  // Decks section header
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
                            '${_decks.length} TOTAL',
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

                  // Decks list empty states
                  if (_decks.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(CupertinoIcons.circle_grid_hex, size: 48, color: Colors.grey[700]),
                              const SizedBox(height: 16),
                              const Text(
                                'No Custom Decks Found',
                                style: TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Start building by clicking the "Initialize New Deck" above!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // Decks list grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final deck = _decks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _DeckListItem(
                                deck: deck,
                                allDecks: _decks,
                                onDelete: () => _deleteDeck(deck),
                                onUpdate: () {
                                  setState(() {});
                                },
                              ),
                            );
                          },
                          childCount: _decks.length,
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
  final DeckModel deck;
  final List<DeckModel> allDecks;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const _DeckListItem({
    Key? key,
    required this.deck,
    required this.allDecks,
    required this.onDelete,
    required this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final leader = deck.leader;
    final cardColor = leader.getPrimaryColor();
    final count = deck.totalCardCount;

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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DeckEditorScreen(
                  deck: deck,
                  allDecks: allDecks,
                  onDeckUpdated: onUpdate,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                // Deck Color Palette Indicator Icon (using safety circular colors)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: leader.getCardGradient(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cardColor.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.circle_grid_hex_fill,
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
                      // Set tags / details
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              leader.rarity,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.style, size: 12, color: const Color(0xFFFFD700).withOpacity(0.8)),
                          const SizedBox(width: 3),
                          Text(
                            leader.cardId,
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
                        deck.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Leader Info
                      Text(
                        'Leader: ${leader.name}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Card Count Badge & Delete Action
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: count == 50
                                ? const Color(0xFF2E7D32).withOpacity(0.2)
                                : const Color(0xFFFFD700).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: count == 50
                                  ? const Color(0xFF81C784).withOpacity(0.4)
                                  : const Color(0xFFFFD700).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '$count/50',
                            style: TextStyle(
                              color: count == 50
                                  ? const Color(0xFF81C784)
                                  : const Color(0xFFFFD700),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Tournament QR button
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => DeckQrScreen(deck: deck),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.qrcode,
                            color: Color(0xFF3B82F6), size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.trash,
                          color: Colors.red[300],
                          size: 18,
                        ),
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
