import 'package:flutter/material.dart';
import '../models/set_model.dart';
import '../models/card_model.dart';
import '../services/data_service.dart';
import '../widgets/card_item.dart';

class CardListScreen extends StatefulWidget {
  final SetModel set;

  const CardListScreen({Key? key, required this.set}) : super(key: key);

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _searchController = TextEditingController();

  List<CardModel> _allCards = [];
  List<CardModel> _filteredCards = [];
  bool _isLoading = true;

  // Search & Filter state
  String _searchQuery = '';
  String _selectedType = 'All';
  String _selectedColor = 'All';
  String _selectedRarity = 'All';

  // Expansion and Animation state
  bool _filtersExpanded = false;
  double _scale = 0.94;
  double _yOffset = 40.0;

  // Filters Lists
  final List<String> _types = ['All', 'Leader', 'Character', 'Event', 'Stage'];
  final List<String> _colors = ['All', 'Red', 'Green', 'Blue', 'Purple', 'Black', 'Yellow'];
  final List<String> _rarities = ['All', 'L', 'SEC', 'SR', 'R', 'UC', 'C'];

  bool get _hasActiveFilters {
    return _selectedType != 'All' || _selectedColor != 'All' || _selectedRarity != 'All';
  }

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
    });

    final cards = await _dataService.getCards(widget.set.setCode);

    setState(() {
      _allCards = cards;
      _filteredCards = cards;
      _isLoading = false;
    });

    // Trigger the premium entrance transition after the screen has loaded the cards
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _scale = 1.0;
          _yOffset = 0.0;
        });
      }
    });
  }

  void _applyFilters() {
    final filtered = _dataService.filterCards(
      sourceCards: _allCards,
      query: _searchQuery,
      typeFilter: _selectedType,
      colorFilter: _selectedColor,
      rarityFilter: _selectedRarity,
    );

    setState(() {
      _filteredCards = filtered;
    });
  }

  void _resetAllFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedType = 'All';
      _selectedColor = 'All';
      _selectedRarity = 'All';
      _filteredCards = _allCards;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.set.setCode,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            )
          : AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, _yOffset, 0)..multiply(Matrix4.diagonal3Values(_scale, _scale, 1.0)),
              transformAlignment: Alignment.center,
              child: Column(
                children: [
                  // Set Header info & description
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.set.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.set.totalCards} cards • Released ${widget.set.releaseDate}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Search & Filter Panel
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Column(
                      children: [
                        // Search Row (Input & Toggle button)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  _searchQuery = val;
                                  _applyFilters();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search card by name, ID, or effect...',
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
                            ),
                            const SizedBox(width: 10),
                            // Expandable filter toggle button with premium styling
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _filtersExpanded = !_filtersExpanded;
                                });
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _filtersExpanded
                                          ? const Color(0xFFFFD700).withOpacity(0.15)
                                          : const Color(0xFF0F172A), // Matches AppTheme surfaceBg
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _filtersExpanded
                                            ? const Color(0xFFFFD700).withOpacity(0.5)
                                            : Colors.white.withOpacity(0.05),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      _filtersExpanded
                                          ? Icons.filter_alt_rounded
                                          : Icons.filter_alt_outlined,
                                      color: _filtersExpanded
                                          ? const Color(0xFFFFD700)
                                          : Colors.grey[400],
                                      size: 22,
                                    ),
                                  ),
                                  // Gilded badge dot if active filters are hidden
                                  if (!_filtersExpanded && _hasActiveFilters)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD700),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF0A0F1E), // Match scaffoldBg
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFD700).withOpacity(0.6),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Filters rows wrapped in an AnimatedContainer
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: _filtersExpanded ? 120.0 : 0.0,
                          margin: EdgeInsets.only(top: _filtersExpanded ? 12.0 : 0.0),
                          child: ClipRect(
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  _buildFilterRow(
                                    label: 'Type',
                                    items: _types,
                                    selectedValue: _selectedType,
                                    onSelected: (val) {
                                      setState(() {
                                        _selectedType = val;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _buildFilterRow(
                                    label: 'Color',
                                    items: _colors,
                                    selectedValue: _selectedColor,
                                    onSelected: (val) {
                                      setState(() {
                                        _selectedColor = val;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  _buildFilterRow(
                                    label: 'Rarity',
                                    items: _rarities,
                                    selectedValue: _selectedRarity,
                                    onSelected: (val) {
                                      setState(() {
                                        _selectedRarity = val;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Search statistics
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SHOWING ${_filteredCards.length} OF ${_allCards.length} CARDS',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty ||
                                _selectedType != 'All' ||
                                _selectedColor != 'All' ||
                                _selectedRarity != 'All')
                              GestureDetector(
                                onTap: _resetAllFilters,
                                child: const Text(
                                  'RESET FILTERS',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),

                // Cards Dense Grid
                Expanded(
                  child: _filteredCards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[700]),
                              const SizedBox(height: 16),
                              const Text(
                                'No Cards Found',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try adjusting your search query or filters',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: _filteredCards.length,
                          itemBuilder: (context, index) {
                            return CardItem(
                              card: _filteredCards[index],
                              compact: true,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFilterRow({
    required String label,
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Container(
            width: 52,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.toLowerCase() == selectedValue.toLowerCase();

                Color? chipTextColor;
                Color? chipBgColor;
                if (label == 'Color' && item != 'All') {
                  switch (item.toLowerCase()) {
                    case 'red':
                      chipTextColor = const Color(0xFFEF5350);
                      break;
                    case 'green':
                      chipTextColor = const Color(0xFF66BB6A);
                      break;
                    case 'blue':
                      chipTextColor = const Color(0xFF42A5F5);
                      break;
                    case 'purple':
                      chipTextColor = const Color(0xFFAB47BC);
                      break;
                    case 'black':
                      chipTextColor = Colors.white70;
                      break;
                    case 'yellow':
                      chipTextColor = const Color(0xFFFFD54F);
                      break;
                  }
                  if (isSelected) {
                    chipBgColor = chipTextColor?.withOpacity(0.2);
                  }
                }

                return GestureDetector(
                  onTap: () => onSelected(item),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: chipBgColor ??
                          (isSelected
                              ? const Color(0xFFFFD700).withOpacity(0.18)
                              : const Color(0xFF1E293B)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? (chipTextColor ?? const Color(0xFFFFD700))
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isSelected ? (chipTextColor ?? const Color(0xFFFFD700)) : Colors.white60,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
