import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';
import '../models/deck_model.dart';
import '../services/data_service.dart';
import 'detail_screen.dart';

class DeckEditorScreen extends StatefulWidget {
  final DeckModel deck;
  final List<DeckModel> allDecks;
  final VoidCallback onDeckUpdated;

  const DeckEditorScreen({
    Key? key,
    required this.deck,
    required this.allDecks,
    required this.onDeckUpdated,
  }) : super(key: key);

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen> with SingleTickerProviderStateMixin {
  final DataService _dataService = DataService();
  late TabController _tabController;
  
  // Catalog search/filter state
  List<CardModel> _catalogCards = [];
  List<CardModel> _filteredCatalogCards = [];
  bool _isLoadingCatalog = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'All';
  String _selectedRarity = 'All';
  String _selectedCost = 'All';

  final List<String> _types = ['All', 'Character', 'Event', 'Stage'];
  final List<String> _rarities = ['All', 'SEC', 'SR', 'R', 'UC', 'C'];
  final List<String> _costs = ['All', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoadingCatalog = true;
    });

    final allCards = await _dataService.getAllCards();
    
    // Filter cards to match the Leader's colors AND not be Leader cards
    final validCards = allCards.where((card) {
      return widget.deck.isCardValidForLeader(card);
    }).toList();

    // Sort valid cards logically: Set code first, then card ID
    validCards.sort((a, b) => a.cardId.compareTo(b.cardId));

    setState(() {
      _catalogCards = validCards;
      _filteredCatalogCards = validCards;
      _isLoadingCatalog = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredCatalogCards = _catalogCards.where((card) {
        // Search query
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          final nameMatch = card.name.toLowerCase().contains(q);
          final idMatch = card.cardId.toLowerCase().contains(q);
          final effectMatch = card.effect?.toLowerCase().contains(q) ?? false;
          final typeMatch = card.type?.toLowerCase().contains(q) ?? false;
          
          if (!nameMatch && !idMatch && !effectMatch && !typeMatch) {
            return false;
          }
        }

        // Type filter
        if (_selectedType != 'All') {
          if (card.cardType.toLowerCase() != _selectedType.toLowerCase()) {
            return false;
          }
        }

        // Rarity filter
        if (_selectedRarity != 'All') {
          if (card.rarity.toUpperCase() != _selectedRarity.toUpperCase()) {
            return false;
          }
        }

        // Cost filter
        if (_selectedCost != 'All') {
          if (card.cost != _selectedCost) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _resetCatalogFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedType = 'All';
      _selectedRarity = 'All';
      _selectedCost = 'All';
      _filteredCatalogCards = _catalogCards;
    });
  }

  // Add card operation
  void _addCard(CardModel card) {
    final currentCount = widget.deck.getCardCount(card.cardId);
    final currentBaseCount = widget.deck.getBaseCardCount(card.cardId);

    // Rule 1: Max 4 copies per base card ID
    if (currentBaseCount >= 4) {
      _showWarningSnackBar('Sudah playset (maksimal 4 kartu)!');
      return;
    }

    setState(() {
      widget.deck.cards[card.cardId] = currentCount + 1;
    });

    _saveDeckChanges();
  }

  // Remove card operation
  void _removeCard(String cardId) {
    final currentCount = widget.deck.getCardCount(cardId);
    if (currentCount <= 0) return;

    setState(() {
      if (currentCount == 1) {
        widget.deck.cards.remove(cardId);
      } else {
        widget.deck.cards[cardId] = currentCount - 1;
      }
    });

    _saveDeckChanges();
  }

  Future<void> _saveDeckChanges() async {
    await _dataService.saveDecks(widget.allDecks);
    widget.onDeckUpdated();
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.black, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFD700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRenameDeckDialog() {
    String tempName = widget.deck.name;
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Rename Deck'),
          content: Column(
            children: [
              const SizedBox(height: 12),
              CupertinoTextField(
                placeholder: 'Deck Name',
                placeholderStyle: const TextStyle(color: CupertinoColors.placeholderText),
                style: const TextStyle(color: CupertinoColors.white),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                controller: TextEditingController(text: widget.deck.name),
                onChanged: (value) {
                  tempName = value;
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
              child: const Text('Save', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              onPressed: () {
                if (tempName.trim().isNotEmpty) {
                  setState(() {
                    widget.deck.name = tempName.trim();
                  });
                  _saveDeckChanges();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaderColor = widget.deck.leader.getPrimaryColor();
    final totalCount = widget.deck.totalCardCount;

    // Premium progress bar coloring
    Color progressColor = const Color(0xFFFFD700); // gold
    if (totalCount == 50) {
      progressColor = const Color(0xFF66BB6A); // completion green
    } else if (totalCount > 50) {
      progressColor = const Color(0xFFEF5350); // warning red
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showRenameDeckDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.deck.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.pencil, size: 14, color: Color(0xFFFFD700)),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Column(
            children: [
              // High-fidelity progress indicator bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Leader: ${widget.deck.leader.name}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$totalCount / 50 cards',
                          style: TextStyle(
                            color: progressColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 6,
                        color: const Color(0xFF1E293B),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: (totalCount / 50).clamp(0.0, 1.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: progressColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: progressColor.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Glassmorphic navigation tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Container(
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
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4), width: 1),
                  ),
                  labelColor: const Color(0xFFFFD700),
                  unselectedLabelColor: Colors.grey[400],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                  tabs: const [
                    Tab(text: 'DECK LIST'),
                    Tab(text: 'CARD CATALOG'),
                  ],
                ),
              ),
            ),

            // Tab View Area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDeckListTab(context),
                  _buildCardCatalogTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 1: DECK LIST ====================
  Widget _buildDeckListTab(BuildContext context) {
    if (widget.deck.cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.circle_grid_hex_fill, size: 64, color: Colors.grey[800]),
            const SizedBox(height: 20),
            const Text(
              'Your Deck is Empty',
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Switch to Card Catalog tab to start adding cards!',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              color: const Color(0xFFFFD700).withOpacity(0.12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              borderRadius: BorderRadius.circular(12),
              child: const Text('Go to Catalog', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              onPressed: () {
                _tabController.animateTo(1);
              },
            ),
          ],
        ),
      );
    }

    // Load full details for each added card to display nicely
    // If they aren't fully resolved yet, we map from _catalogCards
    final List<MapEntry<String, int>> deckEntries = widget.deck.cards.entries.toList();
    
    // Sort deck entries logically by ID
    deckEntries.sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: deckEntries.length + 1, // +1 for the Leader banner at top
      itemBuilder: (context, index) {
        if (index == 0) {
          // Leader prominence banner at top
          final leader = widget.deck.leader;
          final leaderColor = leader.getPrimaryColor();
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E293B), leaderColor.withOpacity(0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: leaderColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black38, blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => DetailScreen(card: leader)),
                );
              },
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 50,
                      height: 70,
                      child: CachedNetworkImage(
                        imageUrl: leader.cardImageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Container(
                          color: leaderColor,
                          child: const Icon(CupertinoIcons.photo, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'DECK LEADER',
                            style: TextStyle(color: Color(0xFFFFD700), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          leader.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${leader.cardId} • ${leader.rarity} • Life: ${leader.life ?? "N/A"}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 16),
                ],
              ),
            ),
          );
        }

        final entry = deckEntries[index - 1];
        final cardId = entry.key;
        final count = entry.value;

        // Try to find the card in our resolved catalog cards
        final card = _catalogCards.firstWhere(
          (c) => c.cardId == cardId,
          orElse: () => CardModel(
            cardId: cardId,
            name: 'Loading Card...',
            rarity: 'C',
            cardType: 'Character',
            cardImageUrl: '',
          ),
        );

        final cardColor = card.getPrimaryColor();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            children: [
              // Card image preview
              GestureDetector(
                onTap: () {
                  if (card.name != 'Loading Card...') {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => DetailScreen(card: card)),
                    );
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 40,
                    height: 56,
                    child: CachedNetworkImage(
                      imageUrl: card.cardImageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(
                        color: cardColor,
                        child: const Icon(CupertinoIcons.photo, color: Colors.white54, size: 16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          card.cardId,
                          style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          card.cardType,
                          style: TextStyle(color: cardColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        if (card.cost != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Cost: ${card.cost}',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),

              // Quantity selectors (+ and - buttons)
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _removeCard(cardId),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.minus, color: Colors.white70, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 20,
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _addCard(card),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.2)),
                      ),
                      child: const Icon(CupertinoIcons.plus, color: Color(0xFFFFD700), size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== TAB 2: CARD CATALOG ====================
  Widget _buildCardCatalogTab(BuildContext context) {
    if (_isLoadingCatalog) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    }

    return Column(
      children: [
        // Advanced Filters row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
          child: Column(
            children: [
              // Search input
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  _searchQuery = val;
                  _applyFilters();
                },
                decoration: InputDecoration(
                  hintText: 'Search valid cards...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _applyFilters();
                            });
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              // Filter Dropdowns Row
              Row(
                children: [
                  // Type Filter Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedType,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedType = val;
                                _applyFilters();
                              });
                            }
                          },
                          items: _types.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Cost Filter Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCost,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCost = val;
                                _applyFilters();
                              });
                            }
                          },
                          items: _costs.map((String cost) {
                            return DropdownMenuItem<String>(
                              value: cost,
                              child: Text(cost == 'All' ? 'Cost: All' : 'Cost: $cost'),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Rarity Filter Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRarity,
                          dropdownColor: const Color(0xFF0F172A),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedRarity = val;
                                _applyFilters();
                              });
                            }
                          },
                          items: _rarities.map((String rarity) {
                            return DropdownMenuItem<String>(
                              value: rarity,
                              child: Text(rarity),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Statistics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredCatalogCards.length} VALID CARDS AVAILABLE',
                    style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  if (_searchQuery.isNotEmpty || _selectedType != 'All' || _selectedRarity != 'All' || _selectedCost != 'All')
                    GestureDetector(
                      onTap: _resetCatalogFilters,
                      child: const Text(
                        'RESET FILTERS',
                        style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Grid Area
        Expanded(
          child: _filteredCatalogCards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[700]),
                      const SizedBox(height: 12),
                      const Text(
                        'No Valid Cards Match Filters',
                        style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _filteredCatalogCards.length,
                  itemBuilder: (context, index) {
                    final card = _filteredCatalogCards[index];
                    final cardColor = card.getPrimaryColor();
                    final countInDeck = widget.deck.getCardCount(card.cardId);

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: countInDeck > 0 ? const Color(0xFFFFD700).withOpacity(0.5) : Colors.white.withOpacity(0.04),
                          width: countInDeck > 0 ? 1.5 : 1.0,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Card image details
                          Positioned.fill(
                            bottom: 36,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => DetailScreen(card: card)),
                                  );
                                },
                                child: CachedNetworkImage(
                                  imageUrl: card.cardImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) => Container(
                                    color: Colors.black26,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white30))),
                                  ),
                                  errorWidget: (c, u, e) => Container(
                                    color: cardColor,
                                    child: Center(
                                      child: Text(
                                        card.cardId,
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Current Count Badge
                          if (countInDeck > 0)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Text(
                                  '${countInDeck}x',
                                  style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),

                          // Quick Add overlay button
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 36,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F172A),
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
                              ),
                              child: InkWell(
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                                onTap: () => _addCard(card),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.plus_circle,
                                      size: 14,
                                      color: countInDeck >= 4 ? Colors.grey : const Color(0xFFFFD700),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      countInDeck >= 4 ? 'MAX (4)' : 'ADD TO DECK',
                                      style: TextStyle(
                                        color: countInDeck >= 4 ? Colors.grey : Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
