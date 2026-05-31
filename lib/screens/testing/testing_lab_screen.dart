import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/deck_model.dart';
import '../../services/data_service.dart';
import 'preset_decks.dart';
import 'deck_test_screen.dart';
import 'how_to_play_screen.dart';

class TestingLabScreen extends StatefulWidget {
  const TestingLabScreen({Key? key}) : super(key: key);

  @override
  State<TestingLabScreen> createState() => _TestingLabScreenState();
}

class _TestingLabScreenState extends State<TestingLabScreen> {
  final DataService _dataService = DataService();
  bool _isLoading = true;
  List<DeckModel> _userDecks = [];
  List<DeckModel> _presetDeckModels = [];
  List<PresetDeckInfo> _presetInfos = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _dataService.getAllCards();
    final allCardsMap = _dataService.allCardsMap;
    final userDecks = await _dataService.loadDecks();
    final presetInfos = PresetDecks.getAll();
    final presetModels = <DeckModel>[];
    for (final info in presetInfos) {
      final m = info.toDeckModel(allCardsMap);
      if (m != null) presetModels.add(m);
    }
    setState(() {
      _userDecks = userDecks;
      _presetDeckModels = presetModels;
      _presetInfos = presetInfos;
      _isLoading = false;
    });
  }

  void _startTest(DeckModel deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeckTestScreen(deck: deck),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeader(),
                  _buildHowToPlayBanner(),
                  _buildSectionTitle('🃏 STARTER DECK PRESETS', '4 latest official decks'),
                  _buildPresetList(),
                  if (_userDecks.isNotEmpty) ...[
                    _buildSectionTitle('📦 YOUR DECKS', '${_userDecks.length} custom decks'),
                    _buildUserDeckList(),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TESTING LAB',
                style: TextStyle(color: Color(0xFFFFD700), fontSize: 12,
                    fontWeight: FontWeight.bold, letterSpacing: 4)),
            const SizedBox(height: 4),
            const Text('Deck Simulator',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Test your deck mechanics and practice gameplay',
                style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToPlayBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HowToPlayScreen())),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E3A5F), const Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('📖', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How to Play One Piece TCG',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Rules, phases, effects & victory conditions',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String sub) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11,
                fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetList() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const BouncingScrollPhysics(),
          itemCount: _presetDeckModels.length,
          itemBuilder: (ctx, i) {
            if (i >= _presetInfos.length) return const SizedBox();
            return _PresetDeckCard(
              deck: _presetDeckModels[i],
              info: _presetInfos[i],
              onTap: () => _startTest(_presetDeckModels[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserDeckList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UserDeckCard(
              deck: _userDecks[i],
              onTap: () => _startTest(_userDecks[i]),
            ),
          ),
          childCount: _userDecks.length,
        ),
      ),
    );
  }
}

class _PresetDeckCard extends StatelessWidget {
  final DeckModel deck;
  final PresetDeckInfo info;
  final VoidCallback onTap;
  const _PresetDeckCard({required this.deck, required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = deck.leader.getPrimaryColor();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: deck.leader.cardImageUrl,
                  httpHeaders: kIsWeb ? null : const {'User-Agent': 'Mozilla/5.0'},
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: color.withOpacity(0.3),
                    child: Center(child: Text(deck.leader.name[0],
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(info.setCode,
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 6),
                  Text(info.name,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.play_circle_fill, color: Color(0xFFFFD700), size: 14),
                      const SizedBox(width: 4),
                      const Text('Test Deck', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDeckCard extends StatelessWidget {
  final DeckModel deck;
  final VoidCallback onTap;
  const _UserDeckCard({required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = deck.leader.getPrimaryColor();
    final count = deck.totalCardCount;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(gradient: deck.leader.getCardGradient(), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.circle_grid_hex_fill, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text('${deck.leader.name} • $count/50 cards',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: const Text('TEST', style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
