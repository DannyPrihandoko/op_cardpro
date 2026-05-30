import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/tournament_model.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import 'qr_scanner_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final TournamentModel tournament;
  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TournamentModel _t;
  late TabController _tabController;
  final _dataService = DataService();
  bool _isSaving = false;
  // Keys for screenshot per-round
  final Map<int, GlobalKey> _roundKeys = {};

  @override
  void initState() {
    super.initState();
    _t = widget.tournament;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Persistence ──────────────────────────────────────────────────────────────

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final all = await _dataService.loadTournaments();
    final idx = all.indexWhere((t) => t.id == _t.id);
    if (idx >= 0) all[idx] = _t; else all.add(_t);
    await _dataService.saveTournaments(all);
    if (mounted) setState(() => _isSaving = false);
  }

  // ── QR Scan → Add Participant ─────────────────────────────────────────────

  Future<void> _scanQr() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result == null) return;

    // Check duplicate
    final isDuplicate = _t.participants
        .any((p) => p.deckId == result['deckId'] && p.playerName == result['playerName']);
    if (isDuplicate) {
      _alert('Already Registered', 'This player/deck is already in the tournament.');
      return;
    }
    if (_t.isFull) {
      _alert('Tournament Full', 'Maximum players (${_t.maxPlayers}) reached.');
      return;
    }

    final p = TournamentParticipant(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      playerName: result['playerName'] as String,
      deckId: result['deckId'] as String,
      deckName: result['deckName'] as String,
      leaderName: '${result['leaderName']} (${result['leaderId']})',
    );
    setState(() => _t.participants.add(p));
    await _save();
  }

  // ── Admin actions ──────────────────────────────────────────────────────────

  Future<void> _startTournament() async {
    if (_t.participants.length < 2) {
      _alert('Not Enough Players', 'Need at least 2 players to start.'); return;
    }
    setState(() {
      _t.status = TournamentStatus.roundRobin;
      _t.currentRound = 1;
      _t.totalSwissRounds = _t.recommendedSwissRounds;
      _t.matches.addAll(_t.generateSwissPairings(1));
    });
    await _save();
    _tabController.animateTo(1);
  }

  Future<void> _advanceRound() async {
    if (!_t.isRoundComplete(_t.currentRound)) {
      _alert('Round Incomplete', 'Complete all matches first.'); return;
    }
    if (_t.currentRound >= _t.totalSwissRounds) {
      _alert('Swiss Done', 'All Swiss rounds complete. Start Top Cut.'); return;
    }
    setState(() {
      _t.currentRound++;
      _t.matches.addAll(_t.generateSwissPairings(_t.currentRound));
    });
    await _save();
  }

  Future<void> _startTopCut() async {
    if (!_t.isRoundComplete(_t.currentRound)) {
      _alert('Round Incomplete', 'Complete all Swiss matches first.'); return;
    }
    if (_t.participants.length < _t.topCutSize) {
      _alert('Not Enough', 'Need ${_t.topCutSize} players for Top Cut.'); return;
    }
    setState(() {
      _t.status = TournamentStatus.topCut;
      _t.matches.addAll(_t.generateTopCutBracket());
    });
    await _save();
    _tabController.animateTo(1);
  }

  Future<void> _advanceTopCut() async {
    final tc = _t.getAllTopCutMatches();
    if (tc.isEmpty) return;
    final last = tc.map((m) => m.round).reduce((a, b) => a > b ? a : b);
    if (!_t.isTopCutRoundComplete(last)) {
      _alert('Round Incomplete', 'Complete all matches first.'); return;
    }
    if (_t.isTopCutFinished) {
      setState(() => _t.status = TournamentStatus.finished);
      await _save(); return;
    }
    final next = _t.advanceTopCut();
    if (next.isEmpty) {
      setState(() => _t.status = TournamentStatus.finished);
    } else {
      setState(() => _t.matches.addAll(next));
    }
    await _save();
  }

  // ── Match result ───────────────────────────────────────────────────────────

  void _showMatchDialog(TournamentMatch match) {
    final p1 = _t.getParticipant(match.player1Id);
    final p2 = match.isBye ? null : _t.getParticipant(match.player2Id);
    if (p1 == null) return;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Input Match Result'),
        content: Text('${p1.playerName} vs ${p2?.playerName ?? "BYE"}'),
        actions: [
          if (!match.isBye) ...[
            CupertinoDialogAction(
              onPressed: () { Navigator.pop(context); _applyResult(match, match.player1Id, false); },
              child: Text('${p1.playerName} Wins'),
            ),
            CupertinoDialogAction(
              onPressed: () { Navigator.pop(context); _applyResult(match, match.player2Id, false); },
              child: Text('${p2?.playerName ?? ''} Wins'),
            ),
            CupertinoDialogAction(
              onPressed: () { Navigator.pop(context); _applyResult(match, null, true); },
              child: const Text('Draw'),
            ),
          ],
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _applyResult(TournamentMatch match, String? winnerId, bool isDraw) {
    setState(() {
      match.winnerId = isDraw ? null : winnerId;
      match.isDraw = isDraw;
      _t.recalculateStandings();
    });
    _save();
  }

  // ── Share round as image ──────────────────────────────────────────────────

  Future<void> _shareRound(int round, bool isTopCut) async {
    final key = _roundKeys[round];
    if (key == null) return;
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final img = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final label = isTopCut ? 'TopCut_R$round' : 'Round$round';
      final file = File('${dir.path}/${_t.name}_$label.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🏆 ${_t.name} — ${isTopCut ? "Top Cut Round ${round - _t.totalSwissRounds}" : "Round $round"} Results',
      );
    } catch (e) {
      _alert('Share Failed', e.toString());
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _alert(String title, String msg) => showCupertinoDialog(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(title), content: Text(msg),
      actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
    ),
  );

  Color _statusColor(TournamentStatus s) {
    switch (s) {
      case TournamentStatus.registration: return const Color(0xFF3B82F6);
      case TournamentStatus.roundRobin:   return const Color(0xFFF59E0B);
      case TournamentStatus.topCut:       return const Color(0xFFEF4444);
      case TournamentStatus.finished:     return const Color(0xFF10B981);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar()],
        body: Column(children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildStandings(), _buildRounds(), _buildParticipants()],
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _buildAdminBar(),
    );
  }

  Widget _buildAppBar() {
    final sc = _statusColor(_t.status);
    return SliverAppBar(
      backgroundColor: AppTheme.surfaceBg,
      pinned: true,
      expandedHeight: 120,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
        title: Text(_t.name,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
          padding: const EdgeInsets.fromLTRB(20, 55, 20, 16),
          child: Row(children: [
            const Icon(CupertinoIcons.flag_fill, color: AppTheme.accentGold, size: 24),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sc.withOpacity(0.4)),
              ),
              child: Text(_t.status.label,
                  style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Text('${_t.participants.length}/${_t.maxPlayers} · Top ${_t.topCutSize}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _buildTabBar() => Container(
    color: AppTheme.surfaceBg,
    child: TabBar(
      controller: _tabController,
      indicatorColor: AppTheme.accentGold,
      labelColor: AppTheme.accentGold,
      unselectedLabelColor: AppTheme.textSecondary,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      tabs: const [Tab(text: 'Standings'), Tab(text: 'Rounds'), Tab(text: 'Players')],
    ),
  );

  // ── Standings ──────────────────────────────────────────────────────────────

  Widget _buildStandings() {
    final list = _t.getStandings();
    if (list.isEmpty) return _empty(CupertinoIcons.chart_bar, 'No standings yet');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final p = list[i]; final rank = i + 1;
        final inCut = rank <= _t.topCutSize && _t.status != TournamentStatus.registration;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: inCut ? AppTheme.accentGold.withOpacity(0.07) : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: inCut ? AppTheme.accentGold.withOpacity(0.25) : Colors.white.withOpacity(0.06)),
          ),
          child: Row(children: [
            SizedBox(width: 32,
              child: Text('#$rank', style: TextStyle(
                color: rank <= 3 ? AppTheme.accentGold : AppTheme.textSecondary,
                fontWeight: FontWeight.bold, fontSize: 14))),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.playerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(p.leaderName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Text('${p.wins}W ${p.losses}L ${p.draws}D',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
              child: Text('${p.points}pts', style: const TextStyle(
                color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ]),
        );
      },
    );
  }

  // ── Rounds ─────────────────────────────────────────────────────────────────

  Widget _buildRounds() {
    if (_t.status == TournamentStatus.registration) {
      return _empty(CupertinoIcons.game_controller, 'Start the tournament to generate pairings');
    }
    final sections = <Widget>[];
    for (int r = 1; r <= _t.totalSwissRounds; r++) {
      final rm = _t.getMatchesForRound(r);
      if (rm.isEmpty) continue;
      sections.add(_roundSection('Round $r (Swiss)', rm, r, false));
    }
    if (_t.status == TournamentStatus.topCut || _t.status == TournamentStatus.finished) {
      final tc = _t.getAllTopCutMatches();
      if (tc.isNotEmpty) {
        final maxR = tc.map((m) => m.round).reduce((a, b) => a > b ? a : b);
        for (int r = _t.totalSwissRounds + 1; r <= maxR; r++) {
          final rm = _t.getTopCutMatchesForRound(r);
          if (rm.isEmpty) continue;
          final lbl = rm.length == 1 ? '🏆 Grand Finals'
              : rm.length == 2 ? '⚔️ Semi Finals'
              : '🔥 Top Cut ${r - _t.totalSwissRounds}';
          sections.add(_roundSection(lbl, rm, r, true));
        }
      }
    }
    if (sections.isEmpty) return _empty(CupertinoIcons.game_controller, 'No rounds yet');
    return ListView(padding: const EdgeInsets.all(16), children: sections);
  }

  Widget _roundSection(String title, List<TournamentMatch> rm, int round, bool isTopCut) {
    _roundKeys.putIfAbsent(round, () => GlobalKey());
    final done = isTopCut ? _t.isTopCutRoundComplete(round) : _t.isRoundComplete(round);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        Text(title, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const Spacer(),
        if (done)
          IconButton(
            icon: const Icon(CupertinoIcons.share, color: AppTheme.accentGold, size: 20),
            tooltip: 'Share round results',
            onPressed: () => _shareRound(round, isTopCut),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        if (done) const SizedBox(width: 8),
        if (done) const Icon(CupertinoIcons.checkmark_circle_fill,
            color: Color(0xFF10B981), size: 18),
      ]),
      const SizedBox(height: 8),
      // Screenshot-able content
      RepaintBoundary(
        key: _roundKeys[round],
        child: Container(
          color: AppTheme.obsidianBg,
          child: Column(children: [
            // Caption for share image
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: Row(children: [
                const Icon(CupertinoIcons.flag_fill, color: AppTheme.accentGold, size: 14),
                const SizedBox(width: 6),
                Text(_t.name, style: const TextStyle(
                    color: AppTheme.accentGold, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Text('— $title', style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
              ]),
            ),
            ...rm.map((m) => _matchCard(m)),
            const SizedBox(height: 4),
          ]),
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }

  Widget _matchCard(TournamentMatch match) {
    final p1 = _t.getParticipant(match.player1Id);
    final p2 = match.isBye ? null : _t.getParticipant(match.player2Id);
    final w1 = match.winnerId == match.player1Id;
    final w2 = match.winnerId == match.player2Id;
    return GestureDetector(
      onTap: !match.isPlayed ? () => _showMatchDialog(match) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !match.isPlayed
                ? AppTheme.accentGold.withOpacity(0.35)
                : Colors.white.withOpacity(0.06)),
        ),
        child: Row(children: [
          Expanded(child: Text(p1?.playerName ?? '?',
              style: TextStyle(
                color: w1 ? AppTheme.accentGold : Colors.white,
                fontWeight: w1 ? FontWeight.bold : FontWeight.normal,
                fontSize: 13),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: match.isDraw
                  ? Colors.purple.withOpacity(0.2)
                  : match.isPlayed ? AppTheme.surfaceBg : AppTheme.accentGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6)),
            child: Text(
              match.isBye ? 'BYE' : match.isDraw ? 'DRAW' : 'VS',
              style: TextStyle(
                color: match.isDraw ? Colors.purple : match.isPlayed
                    ? AppTheme.textSecondary : AppTheme.accentGold,
                fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: match.isBye ? const SizedBox() :
            Text(p2?.playerName ?? '?',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: w2 ? AppTheme.accentGold : Colors.white,
                  fontWeight: w2 ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (!match.isPlayed && !match.isBye)
            const Padding(padding: EdgeInsets.only(left: 8),
              child: Icon(CupertinoIcons.pencil_circle,
                  color: AppTheme.accentGold, size: 18)),
        ]),
      ),
    );
  }

  // ── Participants ───────────────────────────────────────────────────────────

  Widget _buildParticipants() {
    if (_t.participants.isEmpty) return _empty(CupertinoIcons.person_2, 'No participants yet.\nScan QR to add players.');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _t.participants.length,
      itemBuilder: (_, i) {
        final p = _t.participants[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(color: AppTheme.surfaceBg, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text('${i+1}', style: const TextStyle(
                  color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 15))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.playerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(p.deckName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(p.leaderName, style: const TextStyle(color: AppTheme.accentGold, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        );
      },
    );
  }

  // ── Admin bar ──────────────────────────────────────────────────────────────

  Widget _buildAdminBar() {
    final tc = _t.getAllTopCutMatches();
    final buttons = <Widget>[];

    if (_t.status == TournamentStatus.registration) {
      buttons.add(_btn('Scan QR — Add Player', CupertinoIcons.qrcode_viewfinder,
          const Color(0xFF3B82F6), _scanQr, outlined: true));
      buttons.add(const SizedBox(height: 8));
      buttons.add(_btn('Start Tournament', CupertinoIcons.play_arrow_solid,
          const Color(0xFF10B981), _startTournament));
    } else if (_t.status == TournamentStatus.roundRobin) {
      if (_t.currentRound < _t.totalSwissRounds) {
        buttons.add(_btn('Next Swiss Round (${_t.currentRound}/${_t.totalSwissRounds})',
            CupertinoIcons.arrow_right_circle_fill, AppTheme.accentGold, _advanceRound));
      } else {
        buttons.add(_btn('Start Top Cut → Top ${_t.topCutSize}',
            CupertinoIcons.flame_fill, const Color(0xFFEF4444), _startTopCut));
      }
    } else if (_t.status == TournamentStatus.topCut) {
      buttons.add(_btn(
        _t.isTopCutFinished ? '🏆 Finish Tournament' : 'Advance Top Cut',
        CupertinoIcons.arrow_right_circle_fill,
        const Color(0xFFEF4444), _advanceTopCut));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppTheme.surfaceBg,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: buttons),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap,
      {bool outlined = false}) {
    if (outlined) {
      return SizedBox(width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: color, side: BorderSide(color: color),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 13)),
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _isSaving ? null : onTap,
        ));
    }
    return SizedBox(width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 13)),
        icon: _isSaving
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _isSaving ? null : onTap,
      ));
  }

  Widget _empty(IconData icon, String msg) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppTheme.textSecondary, size: 48),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          textAlign: TextAlign.center),
    ]),
  );
}
