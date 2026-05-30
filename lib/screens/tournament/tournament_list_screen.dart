import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/tournament_model.dart';
import '../../models/deck_model.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import 'create_tournament_sheet.dart';
import 'tournament_detail_screen.dart';
import 'deck_qr_screen.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  final _ds = DataService();
  List<TournamentModel> _tournaments = [];
  Set<String> _ownedIds = {};
  List<DeckModel> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final t = await _ds.loadTournaments();
    final o = await _ds.getOwnedTournamentIds();
    final d = await _ds.loadDecks();
    if (mounted) setState(() { _tournaments = t; _ownedIds = o; _decks = d; _isLoading = false; });
  }

  Future<void> _createTournament() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const CreateTournamentSheet()),
    );
    if (result == null) return;
    final t = TournamentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: result['name'] as String,
      date: result['date'] as String,
      maxPlayers: result['maxPlayers'] as int,
      topCutSize: result['topCutSize'] as int,
    );
    _tournaments.insert(0, t);
    await _ds.saveTournaments(_tournaments);
    await _ds.addOwnedTournamentId(t.id);
    await _load();
  }

  Future<void> _openDetail(TournamentModel t) async {
    if (!_ownedIds.contains(t.id)) {
      _showNotOwnerSheet(t);
      return;
    }
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: t)));
    await _load();
  }

  void _showNotOwnerSheet(TournamentModel t) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(t.name),
        message: Text(
          'Status: ${t.status.label}\n'
          'Players: ${t.participants.length}/${t.maxPlayers}\n\n'
          'You are not the host of this event.\n'
          'Ask the host to scan your Deck QR to register.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () { Navigator.pop(context); _showMyQr(); },
            child: const Text('Show My Deck QR 🎫'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ),
    );
  }

  void _showMyQr() {
    if (_decks.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('No Decks Found'),
          content: const Text('Build a deck in the Deck Builder first, then generate your tournament QR.'),
          actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _DeckPickerSheet(decks: _decks, onPick: (deck) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => DeckQrScreen(deck: deck)));
      }),
    );
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month-1]} ${dt.year}';
    } catch (_) { return iso; }
  }

  Color _sc(TournamentStatus s) {
    switch (s) {
      case TournamentStatus.registration: return const Color(0xFF3B82F6);
      case TournamentStatus.roundRobin:   return const Color(0xFFF59E0B);
      case TournamentStatus.topCut:       return const Color(0xFFEF4444);
      case TournamentStatus.finished:     return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        icon: const Icon(CupertinoIcons.qrcode, size: 20),
        label: const Text('My Deck QR', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showMyQr,
      ),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.surfaceBg,
          pinned: true,
          title: const Text('Tournaments',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.add, color: AppTheme.accentGold),
              tooltip: 'Create Tournament',
              onPressed: _createTournament,
            ),
          ],
        ),
        if (_isLoading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.accentGold)))
        else if (_tournaments.isEmpty)
          SliverFillRemaining(child: _emptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => _card(_tournaments[i]),
              childCount: _tournaments.length,
            )),
          ),
      ]),
    );
  }

  Widget _emptyState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: AppTheme.cardBg, shape: BoxShape.circle),
        child: const Icon(CupertinoIcons.flag_fill, color: AppTheme.accentGold, size: 48)),
      const SizedBox(height: 20),
      const Text('No Tournaments Yet',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Create an event or wait for the host\nto scan your Deck QR.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.obsidianBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
        icon: const Icon(CupertinoIcons.add, size: 18),
        label: const Text('Create Tournament', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _createTournament,
      ),
    ]),
  );

  Widget _card(TournamentModel t) {
    final isOwner = _ownedIds.contains(t.id);
    final sc = _sc(t.status);
    final winner = t.getWinner();
    return GestureDetector(
      onTap: () => _openDetail(t),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.cardBg, AppTheme.surfaceBg],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOwner ? AppTheme.accentGold.withOpacity(0.3) : Colors.white.withOpacity(0.06)),
          boxShadow: [BoxShadow(color: sc.withOpacity(0.06), blurRadius: 12)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: sc.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: sc.withOpacity(0.15))),
            ),
            child: Row(children: [
              Icon(CupertinoIcons.flag_fill, color: sc, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(t.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8)),
                  child: const Text('HOST', style: TextStyle(
                      color: AppTheme.accentGold, fontSize: 10, fontWeight: FontWeight.bold))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 12, children: [
                _chip(CupertinoIcons.calendar, _fmtDate(t.date)),
                _chip(CupertinoIcons.person_2, '${t.participants.length}/${t.maxPlayers}'),
                _chip(CupertinoIcons.rosette, 'Top ${t.topCutSize}'),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sc.withOpacity(0.3))),
                  child: Text(t.status.label, style: TextStyle(
                      color: sc, fontSize: 11, fontWeight: FontWeight.bold))),
                if (t.status == TournamentStatus.roundRobin) ...[
                  const SizedBox(width: 8),
                  Text('R${t.currentRound}/${t.totalSwissRounds}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
                if (winner != null) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.rosette, color: AppTheme.accentGold, size: 14),
                  const SizedBox(width: 4),
                  Text(winner.playerName, style: const TextStyle(
                      color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
                const Spacer(),
                if (!isOwner)
                  Text('Tap to view info', style: TextStyle(
                      color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 11)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: AppTheme.textSecondary, size: 13),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
  ]);
}

// ── Deck picker bottom sheet ──────────────────────────────────────────────────

class _DeckPickerSheet extends StatelessWidget {
  final List<DeckModel> decks;
  final void Function(DeckModel) onPick;
  const _DeckPickerSheet({required this.decks, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.obsidianBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2))),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text('Select Your Deck',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
        const Divider(color: Color(0x1AFFFFFF)),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: decks.length,
            itemBuilder: (_, i) {
              final d = decks[i];
              return GestureDetector(
                onTap: () => onPick(d),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08))),
                  child: Row(children: [
                    const Icon(CupertinoIcons.hammer_fill, color: AppTheme.accentGold, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${d.leader.name} · ${d.totalCardCount} cards',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ])),
                    const Icon(CupertinoIcons.chevron_right, color: AppTheme.textSecondary, size: 16),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
