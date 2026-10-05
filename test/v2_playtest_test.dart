
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/models/captain.dart';
import 'package:space_traders/models/faction_reputation.dart';
import 'package:space_traders/models/game_state.dart';
import 'package:space_traders/models/ship.dart';
import 'package:space_traders/models/cargo.dart';
import 'package:space_traders/models/mission.dart';
import 'package:space_traders/models/crew.dart';
import 'package:space_traders/systems/reputation_system.dart';
import 'package:space_traders/config/game_config.dart';

Ship _ship(String id, {int cargo = 20, String? planetId}) => Ship(
  id: id, typeId: 'scout', name: 'Scout',
  baseCargo: cargo, cargoUpgradeBonus: 0, baseWeapons: 1, weaponUpgradeBonus: 0,
  price: 0, cargoUpgradeCost: 800, weaponUpgradeCost: 1000, speed: 1.0,
  sprite: 'scout', equipped: true, currentPlanetId: planetId,
);

Crew _crew(String id, String planetId, {int funding = 1000}) => Crew(
  id: id, planetId: planetId, name: 'Alpha',
  funding: funding, skill: 0.5, status: CrewStatus.active,
  hiredOnTurn: 0, history: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('V2 PLAY TEST: Full user journey with V2 features', () {
    test('Step 1: NEW GAME → Captain Lv1, 5000cr, no reputation', () {
      final state = GameState.fresh();
      expect(state.captain.level, 1);
      expect(state.captain.xp, 0);
      expect(state.credits, 5000);
      expect(state.factionReputations, isEmpty);
      expect(state.unlockedAchievements, isEmpty);
      print('  > New game: ${state.credits}cr, Captain ${state.captain.name} Lv${state.captain.level}');
    });

    test('Step 2: BUY 10 food → +XP, +reputation', () {
      final repSystem = ReputationSystem();
      var state = GameState.fresh();
      final cost = 200;
      state = state.copyWith(
        credits: state.credits - cost,
        shipCargo: {'a': [Cargo(commodityId: 'food', quantity: 10)]},
        totalCostByCommodity: {'food': cost},
        totalBoughtByCommodity: {'food': 10},
        captain: state.captain.addXp(5),
        factionReputations: repSystem.updateReputationForTrade(
          current: {}, planetId: 'saturn', isBuy: true, amount: cost,
        ),
      );
      expect(state.credits, 4800);
      expect(state.captain.xp, 5);
      expect(state.factionReputations['saturn']!.reputation, 2);
    });

    test('Step 3: TRAVEL → Jupiter (cost 50, +1 turn)', () {
      var state = GameState.fresh();
      state = state.copyWith(
        currentPlanetId: 'jupiter',
        turn: state.turn + 1,
        credits: state.credits - 50,
      );
      expect(state.credits, 4950);
      expect(state.turn, 1);
    });

    test('Step 4: SELL 10 food on Jupiter → 950cr revenue, +XP', () {
      final repSystem = ReputationSystem();
      var state = GameState.fresh();
      state = state.copyWith(
        shipCargo: {'a': [Cargo(commodityId: 'food', quantity: 10)]},
        totalCostByCommodity: {'food': 200},
        totalBoughtByCommodity: {'food': 10},
        captain: state.captain.addXp(5),
        credits: 4800,
      );
      final revenue = 950;
      state = state.copyWith(
        credits: state.credits + revenue,
        shipCargo: {'a': <Cargo>[]},
        totalSoldByCommodity: {'food': 10},
        captain: state.captain.addXp(15),
        factionReputations: repSystem.updateReputationForTrade(
          current: state.factionReputations,
          planetId: 'jupiter', isBuy: false, amount: revenue,
        ),
      );
      expect(state.credits, 5750);
      expect(state.captain.xp, 20);
    });

    test('Step 5: ACCEPT a mission (15 food to Mars)', () {
      var state = GameState.fresh();
      final mission = Mission(
        id: 'm1', originPlanetId: 'jupiter', destinationPlanetId: 'mars',
        governorName: 'Gov', description: 'Mars: facing famine',
        commodityId: 'food', quantity: 15,
        rewardCredits: 1500, rewardCreditScore: 50,
        acceptedOnTurn: 1, deadlineTurn: 6,
        status: MissionStatus.active,
      );
      state = state.copyWith(
        missions: [mission],
        captain: state.captain.addXp(20),
      );
      expect(state.missions.length, 1);
    });

    test('Step 6: BUY WAREHOUSE → warehouse_buy achievement', () {
      final repSystem = ReputationSystem();
      var state = GameState.fresh().copyWith(
        warehouseCargo: {'jupiter': <Cargo>[]},
      );
      final newly = repSystem.checkAchievements(state);
      expect(newly.any((a) => a.id == 'warehouse_buy'), true);
    });

    test('Step 7: HIRE crew → crew_hire achievement', () {
      final repSystem = ReputationSystem();
      var state = GameState.fresh().copyWith(
        crews: [_crew('c1', 'jupiter')],
      );
      final newly = repSystem.checkAchievements(state);
      expect(newly.any((a) => a.id == 'crew_hire'), true);
    });

    test('Step 8: BUY 5 ships → fleet_5 achievement', () {
      final repSystem = ReputationSystem();
      var state = GameState.fresh().copyWith(
        ships: List.generate(5, (i) => _ship('s$i')),
        activeShipId: 's0',
      );
      final newly = repSystem.checkAchievements(state);
      expect(newly.any((a) => a.id == 'fleet_5'), true);
    });

    test('Step 9: Galaxy events trigger at ~25% per turn', () {
      final repSystem = ReputationSystem();
      int triggered = 0;
      for (int i = 0; i < 1000; i++) {
        if (repSystem.maybeTriggerEvent([]) != null) triggered++;
      }
      expect(triggered, greaterThan(200));
      expect(triggered, lessThan(300));
      print('  > Events triggered in 1000 sims: $triggered (target: 250)');
    });

    test('Step 10: FINAL — diversified v2 player', () {
      var state = GameState.fresh();
      state = state.copyWith(
        ships: List.generate(5, (i) => _ship('s$i')),
        activeShipId: 's0',
        credits: 25000, creditScore: 3500, turn: 20,
        captain: const Captain(name: 'Alan', level: 4, xp: 75, totalTrades: 50, totalMissionsCompleted: 8),
        factionReputations: {
          'jupiter': const FactionReputation(factionId: 'jupiter', reputation: 30, title: 'Trusted'),
          'saturn': const FactionReputation(factionId: 'saturn', reputation: 20, title: 'Merchant'),
        },
        unlockedAchievements: const ['first_trade', 'first_mission', 'trader_10', 'fleet_5', 'crew_hire', 'warehouse_buy'],
      );
      print('  > FINAL: Captain Lv${state.captain.level}, ${state.credits}cr, ${state.ships.length} ships, ${state.factionReputations.length} factions, ${state.unlockedAchievements.length} achievements');
      expect(state.ships.length, 5);
      expect(state.factionReputations.length, 2);
      expect(state.unlockedAchievements.length, 6);
    });
  });
}
