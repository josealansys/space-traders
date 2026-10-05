
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/models/captain.dart';
import 'package:space_traders/models/faction_reputation.dart';
import 'package:space_traders/models/galaxy_event.dart';
import 'package:space_traders/models/game_state.dart';
import 'package:space_traders/models/ship.dart';
import 'package:space_traders/models/mission.dart';
import 'package:space_traders/models/cargo.dart';
import 'package:space_traders/systems/reputation_system.dart';

Ship _ship(String id, {int cargo = 20, String? planetId}) => Ship(
  id: id, typeId: 'scout', name: 'Scout',
  baseCargo: cargo, cargoUpgradeBonus: 0, baseWeapons: 1, weaponUpgradeBonus: 0,
  price: 0, cargoUpgradeCost: 800, weaponUpgradeCost: 1000, speed: 1.0,
  sprite: 'scout', equipped: true, currentPlanetId: planetId,
);

void main() {
  group('V2: Captain model & leveling', () {
    test('1. Captain starts at level 1 with 0 XP', () {
      final cap = Captain(name: 'Alan');
      expect(cap.level, 1);
      expect(cap.xp, 0);
      expect(cap.xpForNextLevel, 100);
    });

    test('2. Captain gains XP and levels up', () {
      final cap = Captain(name: 'Alan');
      final c2 = cap.addXp(50);
      expect(c2.xp, 50);
      expect(c2.level, 1);
      final c3 = c2.addXp(60); // total 110, level up
      expect(c3.level, 2);
      expect(c3.xp, 10); // 110 - 100 for level 2
      expect(c3.xpForNextLevel, 200); // level 2 needs 200
    });
  });

  group('V2: Faction reputation', () {
    test('3. New faction starts at 0 (Outsider)', () {
      final rep = FactionReputation(
        factionId: 'terra', reputation: 0, title: FactionReputation.titleForRep(0),
      );
      expect(rep.title, 'Merchant');
    });

    test('4. Reputation titles based on value', () {
      expect(FactionReputation.titleForRep(-60), 'Hostile');
      expect(FactionReputation.titleForRep(-10), 'Outsider');
      expect(FactionReputation.titleForRep(20), 'Merchant');
      expect(FactionReputation.titleForRep(50), 'Trusted');
      expect(FactionReputation.titleForRep(70), 'Champion');
    });

    test('5. Reputation discount works', () {
      final high = FactionReputation(factionId: 't', reputation: 50, title: 'Trusted');
      expect(high.priceModifier, 0.9); // 10% discount
      final hostile = FactionReputation(factionId: 't', reputation: -50, title: 'Hostile');
      expect(hostile.priceModifier, 1.1); // 10% markup
    });
  });

  group('V2: Galaxy events', () {
    test('6. There are 6 possible galaxy events', () {
      expect(allGalaxyEvents.length, 6);
    });

    test('7. Event durations decrement', () {
      final sys = ReputationSystem();
      final events = [allGalaxyEvents.first];
      final updated = sys.updateEvents(events);
      expect(updated.first.turnsRemaining, 4); // 5 - 1
    });

    test('8. Events expire after 0 turns', () {
      final sys = ReputationSystem();
      final expired = allGalaxyEvents.first.copyWith(turnsRemaining: 1);
      final result = sys.updateEvents([expired]);
      expect(result, isEmpty);
    });
  });

  group('V2: Achievements system', () {
    test('9. 16 achievements defined', () {
      expect(allAchievements.length, 16);
    });

    test('10. First Trade unlocks after first buy', () {
      final sys = ReputationSystem();
      final state = GameState(
        ships: [_ship('a')],
        activeShipId: 'a',
        currentPlanetId: 'terra',
        totalBoughtByCommodity: {'food': 1},
        lastSaved: DateTime.now(),
      );
      final newly = sys.checkAchievements(state);
      final ids = newly.map((a) => a.id).toList();
      expect(ids.contains('first_trade'), true);
      expect(ids.contains('crew_hire'), false);
    });

    test('11. Fleet_5 unlocks when owning 5 ships', () {
      final sys = ReputationSystem();
      final state = GameState(
        ships: List.generate(5, (i) => _ship('s$i')),
        activeShipId: 's0',
        currentPlanetId: 'terra',
        lastSaved: DateTime.now(),
      );
      final newly = sys.checkAchievements(state);
      expect(newly.map((a) => a.id).contains('fleet_5'), true);
    });

    test('12. Achievement rewards (credits + XP)', () {
      final first = allAchievements.firstWhere((a) => a.id == 'first_trade');
      expect(first.creditReward, 100);
      expect(first.xpReward, 10);
    });
  });

  group('V2: GameState integration', () {
    test('13. GameState.fresh() includes V2 defaults', () {
      final s = GameState.fresh();
      expect(s.captain.name, 'Captain');
      expect(s.captain.level, 1);
      expect(s.factionReputations, isEmpty);
      expect(s.unlockedAchievements, isEmpty);
      expect(s.activeEvents, isEmpty);
      expect(s.saveVersion, 2);
    });

    test('14. GameState.copyWith preserves V2 fields', () {
      final s = GameState.fresh();
      final s2 = s.copyWith(
        captain: const Captain(name: 'Alan', level: 5),
        unlockedAchievements: ['first_trade'],
      );
      expect(s2.captain.level, 5);
      expect(s2.unlockedAchievements.length, 1);
      // Other fields preserved
      expect(s2.credits, s.credits);
    });
  });

  group('V2: Trade → XP + reputation', () {
    test('15. Buying at a planet gains reputation', () {
      final sys = ReputationSystem();
      final reps = sys.updateReputationForTrade(
        current: {},
        planetId: 'jupiter',
        isBuy: true,
        amount: 5000,
      );
      // +5 rep (clamped 1-5 for amount 5000)
      expect(reps['jupiter']!.reputation, 5);
      expect(reps['jupiter']!.title, 'Merchant');
    });
  });
}
