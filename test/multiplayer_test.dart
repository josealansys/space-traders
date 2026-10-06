
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/models/player.dart';

void main() {
  group('V2: Player model', () {
    test('1. Create player with name', () {
      final p = Player(
        id: 'p1', name: 'Alan',
        createdAt: DateTime(2026, 1, 1),
        lastPlayed: DateTime(2026, 1, 1),
      );
      expect(p.name, 'Alan');
      expect(p.id, 'p1');
      expect(p.isLocal, true);
    });

    test('2. Player JSON serialization', () {
      final p = Player(
        id: 'p1', name: 'Test',
        createdAt: DateTime(2026, 1, 1),
        lastPlayed: DateTime(2026, 1, 1),
      );
      final json = p.toJson();
      expect(json['name'], 'Test');
      final restored = Player.fromJson(json);
      expect(restored.name, 'Test');
      expect(restored.id, 'p1');
    });

    test('3. Cloud player has cloudUserId', () {
      final p = Player(
        id: 'p1', name: 'Alan',
        createdAt: DateTime(2026, 1, 1),
        lastPlayed: DateTime(2026, 1, 1),
        cloudUserId: 'user_abc',
      );
      expect(p.cloudUserId, 'user_abc');
      expect(p.isLocal, true); // default
    });
  });

  group('V2: SaveSlot', () {
    test('4. Save slot holds player + state', () {
      final player = Player(
        id: 'p1', name: 'Alan',
        createdAt: DateTime(2026, 1, 1),
        lastPlayed: DateTime(2026, 1, 1),
      );
      final save = SaveSlot(
        player: player,
        gameStateJson: {'turn': 5, 'credits': 1000},
        lastSaved: DateTime(2026, 1, 1),
      );
      expect(save.player.name, 'Alan');
      expect(save.gameStateJson['turn'], 5);
    });
  });

  group('V2: Leaderboard scoring', () {
    test('5. Score formula: credits + turn*10 + rep*100', () {
      final score = LeaderboardEntry.calculateScore(
        credits: 5000, turn: 10, reputationSum: 20,
      );
      // 5000 + 100 + 2000 = 7100
      expect(score, 7100);
    });

    test('6. Leaderboard entry JSON', () {
      final entry = LeaderboardEntry(
        playerName: 'Alan', score: 7100,
        credits: 5000, turn: 10, cloudUserId: 'user_1',
        submittedAt: DateTime(2026, 1, 1),
      );
      final json = entry.toJson();
      final restored = LeaderboardEntry.fromJson(json);
      expect(restored.playerName, 'Alan');
      expect(restored.score, 7100);
    });
  });
}
