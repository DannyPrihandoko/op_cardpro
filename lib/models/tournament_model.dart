import 'dart:math';

enum TournamentStatus { registration, roundRobin, topCut, finished }

extension TournamentStatusLabel on TournamentStatus {
  String get label {
    switch (this) {
      case TournamentStatus.registration:
        return 'Registration';
      case TournamentStatus.roundRobin:
        return 'Swiss Rounds';
      case TournamentStatus.topCut:
        return 'Top Cut';
      case TournamentStatus.finished:
        return 'Finished';
    }
  }
}

// ─── Participant ───────────────────────────────────────────────────────────────
class TournamentParticipant {
  final String id;
  final String playerName;
  final String deckId;
  final String deckName;
  final String leaderName;
  int wins;
  int losses;
  int draws;
  bool receivedBye;

  TournamentParticipant({
    required this.id,
    required this.playerName,
    required this.deckId,
    required this.deckName,
    required this.leaderName,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.receivedBye = false,
  });

  int get points => (wins * 3) + draws;
  int get matchesPlayed => wins + losses + draws;
  double get winRate => matchesPlayed == 0 ? 0.0 : wins / matchesPlayed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerName': playerName,
        'deckId': deckId,
        'deckName': deckName,
        'leaderName': leaderName,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'receivedBye': receivedBye,
      };

  factory TournamentParticipant.fromJson(Map<String, dynamic> json) =>
      TournamentParticipant(
        id: json['id'] as String,
        playerName: json['playerName'] as String,
        deckId: json['deckId'] as String,
        deckName: json['deckName'] as String,
        leaderName: json['leaderName'] as String,
        wins: json['wins'] as int? ?? 0,
        losses: json['losses'] as int? ?? 0,
        draws: json['draws'] as int? ?? 0,
        receivedBye: json['receivedBye'] as bool? ?? false,
      );
}

// ─── Match ─────────────────────────────────────────────────────────────────────
class TournamentMatch {
  final String id;
  final int round;
  final bool isTopCut;
  final String player1Id;
  final String player2Id;
  String? winnerId;
  bool isDraw;
  bool isBye;
  int? bracketPosition;

  static const String byePlayerId = '__BYE__';

  TournamentMatch({
    required this.id,
    required this.round,
    required this.player1Id,
    required this.player2Id,
    this.isTopCut = false,
    this.winnerId,
    this.isDraw = false,
    this.isBye = false,
    this.bracketPosition,
  });

  bool get isPlayed => winnerId != null || isDraw || isBye;

  Map<String, dynamic> toJson() => {
        'id': id,
        'round': round,
        'isTopCut': isTopCut,
        'player1Id': player1Id,
        'player2Id': player2Id,
        'winnerId': winnerId,
        'isDraw': isDraw,
        'isBye': isBye,
        'bracketPosition': bracketPosition,
      };

  factory TournamentMatch.fromJson(Map<String, dynamic> json) => TournamentMatch(
        id: json['id'] as String,
        round: json['round'] as int,
        player1Id: json['player1Id'] as String,
        player2Id: json['player2Id'] as String,
        isTopCut: json['isTopCut'] as bool? ?? false,
        winnerId: json['winnerId'] as String?,
        isDraw: json['isDraw'] as bool? ?? false,
        isBye: json['isBye'] as bool? ?? false,
        bracketPosition: json['bracketPosition'] as int?,
      );
}

// ─── Tournament ────────────────────────────────────────────────────────────────
class TournamentModel {
  final String id;
  String name;
  String date;
  int maxPlayers;
  int topCutSize;
  TournamentStatus status;
  List<TournamentParticipant> participants;
  List<TournamentMatch> matches;
  int currentRound;
  int totalSwissRounds;

  TournamentModel({
    required this.id,
    required this.name,
    required this.date,
    required this.maxPlayers,
    required this.topCutSize,
    this.status = TournamentStatus.registration,
    List<TournamentParticipant>? participants,
    List<TournamentMatch>? matches,
    this.currentRound = 0,
    this.totalSwissRounds = 0,
  })  : participants = participants ?? [],
        matches = matches ?? [];

  // Recommended Swiss rounds based on player count
  int get recommendedSwissRounds {
    final n = participants.length;
    if (n <= 4) return 3;
    if (n <= 8) return 4;
    if (n <= 16) return 5;
    if (n <= 32) return 6;
    return 7;
  }

  bool get isFull => participants.length >= maxPlayers;

  // ── Query helpers ────────────────────────────────────────────────────────────

  TournamentParticipant? getParticipant(String id) {
    try {
      return participants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TournamentMatch> getMatchesForRound(int round) =>
      matches.where((m) => m.round == round && !m.isTopCut).toList();

  List<TournamentMatch> getTopCutMatchesForRound(int round) =>
      matches.where((m) => m.isTopCut && m.round == round).toList();

  List<TournamentMatch> getAllTopCutMatches() =>
      matches.where((m) => m.isTopCut).toList();

  bool isRoundComplete(int round) {
    final rm = getMatchesForRound(round);
    return rm.isNotEmpty && rm.every((m) => m.isPlayed);
  }

  bool isTopCutRoundComplete(int round) {
    final rm = getTopCutMatchesForRound(round);
    return rm.isNotEmpty && rm.every((m) => m.isPlayed);
  }

  // ── Standings ────────────────────────────────────────────────────────────────

  List<TournamentParticipant> getStandings() {
    final sorted = List<TournamentParticipant>.from(participants);
    sorted.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.winRate != a.winRate) return b.winRate.compareTo(a.winRate);
      return b.wins.compareTo(a.wins);
    });
    return sorted;
  }

  // Recalculate all stats from match history
  void recalculateStandings() {
    for (final p in participants) {
      p.wins = 0;
      p.losses = 0;
      p.draws = 0;
      p.receivedBye = false;
    }

    for (final m in matches) {
      if (!m.isPlayed || m.isTopCut) continue;

      if (m.isBye) {
        final p = getParticipant(m.player1Id);
        if (p != null) {
          p.wins++;
          p.receivedBye = true;
        }
        continue;
      }

      final p1 = getParticipant(m.player1Id);
      final p2 = getParticipant(m.player2Id);

      if (m.isDraw) {
        p1?.draws++;
        p2?.draws++;
      } else if (m.winnerId != null) {
        if (m.winnerId == m.player1Id) {
          p1?.wins++;
          p2?.losses++;
        } else {
          p1?.losses++;
          p2?.wins++;
        }
      }
    }
  }

  // ── Swiss Pairing ────────────────────────────────────────────────────────────

  List<TournamentMatch> generateSwissPairings(int roundNumber) {
    final standings = getStandings();
    final paired = <String>{};
    final newMatches = <TournamentMatch>[];
    int matchIdx = 0;

    // Build set of already-played pair keys
    final previousPairs = <String>{};
    for (final m in matches) {
      if (!m.isBye) {
        previousPairs.add('${m.player1Id}|${m.player2Id}');
        previousPairs.add('${m.player2Id}|${m.player1Id}');
      }
    }

    String matchId() => '${id}_r${roundNumber}_m$matchIdx';

    for (int i = 0; i < standings.length; i++) {
      final p1 = standings[i];
      if (paired.contains(p1.id)) continue;

      bool found = false;

      // Try to pair with best available opponent (no rematch)
      for (int j = i + 1; j < standings.length; j++) {
        final p2 = standings[j];
        if (paired.contains(p2.id)) continue;
        if (previousPairs.contains('${p1.id}|${p2.id}')) continue;

        newMatches.add(TournamentMatch(
          id: matchId(),
          round: roundNumber,
          player1Id: p1.id,
          player2Id: p2.id,
        ));
        paired.add(p1.id);
        paired.add(p2.id);
        matchIdx++;
        found = true;
        break;
      }

      // Allow rematch if no other option
      if (!found) {
        for (int j = i + 1; j < standings.length; j++) {
          final p2 = standings[j];
          if (paired.contains(p2.id)) continue;

          newMatches.add(TournamentMatch(
            id: matchId(),
            round: roundNumber,
            player1Id: p1.id,
            player2Id: p2.id,
          ));
          paired.add(p1.id);
          paired.add(p2.id);
          matchIdx++;
          break;
        }
      }
    }

    // Handle BYE for odd player count
    final unpaired = standings.where((p) => !paired.contains(p.id)).toList();
    if (unpaired.isNotEmpty) {
      // Give BYE to lowest-ranked player who hasn't had one yet
      final byeTarget = unpaired.reversed.firstWhere(
        (p) => !p.receivedBye,
        orElse: () => unpaired.last,
      );
      newMatches.add(TournamentMatch(
        id: '${id}_r${roundNumber}_bye',
        round: roundNumber,
        player1Id: byeTarget.id,
        player2Id: TournamentMatch.byePlayerId,
        isBye: true,
        winnerId: byeTarget.id,
      ));
      // Immediately apply BYE win
      byeTarget.wins++;
      byeTarget.receivedBye = true;
    }

    return newMatches;
  }

  // ── Top Cut ──────────────────────────────────────────────────────────────────

  List<TournamentMatch> generateTopCutBracket() {
    final standings = getStandings().take(topCutSize).toList();
    final newMatches = <TournamentMatch>[];
    final tcRound = currentRound + 1;

    // Standard seeding: seed 1 vs seed N, seed 2 vs seed N-1, …
    for (int i = 0; i < topCutSize ~/ 2; i++) {
      final high = standings[i];
      final low = standings[topCutSize - 1 - i];
      newMatches.add(TournamentMatch(
        id: '${id}_tc_r${tcRound}_m$i',
        round: tcRound,
        player1Id: high.id,
        player2Id: low.id,
        isTopCut: true,
        bracketPosition: i,
      ));
    }
    return newMatches;
  }

  List<TournamentMatch> advanceTopCut() {
    final tcMatches = getAllTopCutMatches();
    if (tcMatches.isEmpty) return [];

    final lastRound = tcMatches.map((m) => m.round).reduce(max);
    final lastRoundMatches = tcMatches
        .where((m) => m.round == lastRound)
        .toList()
      ..sort((a, b) => (a.bracketPosition ?? 0).compareTo(b.bracketPosition ?? 0));

    if (lastRoundMatches.length <= 1) return []; // Finals done
    if (!lastRoundMatches.every((m) => m.isPlayed)) return [];

    final newRound = lastRound + 1;
    final newMatches = <TournamentMatch>[];

    for (int i = 0; i < lastRoundMatches.length ~/ 2; i++) {
      final m1 = lastRoundMatches[i * 2];
      final m2 = lastRoundMatches[i * 2 + 1];
      final w1 = m1.winnerId ?? m1.player1Id;
      final w2 = m2.winnerId ?? m2.player1Id;

      newMatches.add(TournamentMatch(
        id: '${id}_tc_r${newRound}_m$i',
        round: newRound,
        player1Id: w1,
        player2Id: w2,
        isTopCut: true,
        bracketPosition: i,
      ));
    }
    return newMatches;
  }

  bool get isTopCutFinished {
    if (status != TournamentStatus.topCut &&
        status != TournamentStatus.finished) return false;
    final tcMatches = getAllTopCutMatches();
    if (tcMatches.isEmpty) return false;
    final lastRound = tcMatches.map((m) => m.round).reduce(max);
    final finals = tcMatches.where((m) => m.round == lastRound).toList();
    return finals.length == 1 && finals.first.isPlayed;
  }

  TournamentParticipant? getWinner() {
    if (!isTopCutFinished) return null;
    final tcMatches = getAllTopCutMatches();
    final lastRound = tcMatches.map((m) => m.round).reduce(max);
    final finals = tcMatches.where((m) => m.round == lastRound).toList();
    if (finals.isEmpty) return null;
    final wId = finals.first.winnerId;
    if (wId == null) return null;
    return getParticipant(wId);
  }

  // ── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date,
        'maxPlayers': maxPlayers,
        'topCutSize': topCutSize,
        'status': status.index,
        'participants': participants.map((p) => p.toJson()).toList(),
        'matches': matches.map((m) => m.toJson()).toList(),
        'currentRound': currentRound,
        'totalSwissRounds': totalSwissRounds,
      };

  factory TournamentModel.fromJson(Map<String, dynamic> json) => TournamentModel(
        id: json['id'] as String,
        name: json['name'] as String,
        date: json['date'] as String,
        maxPlayers: json['maxPlayers'] as int,
        topCutSize: json['topCutSize'] as int,
        status: TournamentStatus.values[json['status'] as int? ?? 0],
        participants: (json['participants'] as List<dynamic>?)
                ?.map((p) =>
                    TournamentParticipant.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        matches: (json['matches'] as List<dynamic>?)
                ?.map((m) =>
                    TournamentMatch.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        currentRound: json['currentRound'] as int? ?? 0,
        totalSwissRounds: json['totalSwissRounds'] as int? ?? 0,
      );
}
