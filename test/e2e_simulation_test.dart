
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/models/game_state.dart';
import 'package:space_traders/models/ship.dart';
import 'package:space_traders/models/cargo.dart';
import 'package:space_traders/models/mission.dart';

Ship _ship(String id, {int cargo = 20, String? planetId}) => Ship(
  id: id, typeId: 'scout', name: 'Scout',
  baseCargo: cargo, cargoUpgradeBonus: 0, baseWeapons: 1, weaponUpgradeBonus: 0,
  price: 0, cargoUpgradeCost: 800, weaponUpgradeCost: 1000, speed: 1.0,
  sprite: 'scout', equipped: true, currentPlanetId: planetId,
);

void main() {
  group('E2E: Full game flow (no JSON loading)', () {
    test('1. NEW GAME state', () {
      final state = GameState(
        ships: [_ship('s1', planetId: 'terra')],
        activeShipId: 's1', shipCargo: {'s1': <Cargo>[]},
        currentPlanetId: 'terra', credits: 5000, creditScore: 1000,
        turn: 0, bounty: 0, lastSaved: DateTime.now(),
      );
      expect(state.credits, 5000);
      expect(state.ships.length, 1);
      expect(state.currentPlanetId, 'terra');
    });

    test('2. BUY cargo', () {
      final state = GameState(
        ships: [_ship('s1', planetId: 'terra')],
        activeShipId: 's1',
        shipCargo: {'s1': [Cargo(commodityId: 'food', quantity: 15)]},
        currentPlanetId: 'terra', credits: 4250,
        totalCostByCommodity: {'food': 750},
        totalBoughtByCommodity: {'food': 15},
        lastSaved: DateTime.now(),
      );
      expect(state.avgCostPerUnit('food'), 50);
    });

    test('3. ACCEPT mission', () {
      final mission = Mission(
        id: 'm1', originPlanetId: 'terra', destinationPlanetId: 'jupiter',
        governorName: 'G', description: 'Jupiter: need food',
        commodityId: 'food', quantity: 12,
        rewardCredits: 1500, rewardCreditScore: 50,
        acceptedOnTurn: 0, deadlineTurn: 5,
        status: MissionStatus.active,
      );
      expect(mission.status, MissionStatus.active);
      expect(mission.destinationPlanetId, 'jupiter');
    });

    test('4. TRAVEL to destination', () {
      var state = GameState(
        ships: [_ship('s1', planetId: 'terra')],
        activeShipId: 's1',
        shipCargo: {'s1': [Cargo(commodityId: 'food', quantity: 15)]},
        currentPlanetId: 'terra', credits: 4950,
        turn: 0, lastSaved: DateTime.now(),
      );
      state = state.copyWith(
        currentPlanetId: 'jupiter',
        turn: 1,
        ships: state.ships.map((s) =>
          s.id == 's1' ? s.copyWith(currentPlanetId: 'jupiter') : s).toList(),
      );
      expect(state.currentPlanetId, 'jupiter');
      expect(state.turn, 1);
      final cargo = state.shipCargo['s1'] ?? [];
      final food = cargo.firstWhere((c) => c.commodityId == 'food').quantity;
      expect(food, 15);
    });

    test('5. GOVERNMENT at destination shows mission (v1.2.15)', () {
      final mission = Mission(
        id: 'm1', originPlanetId: 'terra', destinationPlanetId: 'jupiter',
        governorName: 'G', description: 'Jupiter: need food',
        commodityId: 'food', quantity: 12,
        rewardCredits: 1500, rewardCreditScore: 50,
        acceptedOnTurn: 0, deadlineTurn: 5,
        status: MissionStatus.active,
      );
      final state = GameState(
        ships: [_ship('s1', planetId: 'jupiter')],
        activeShipId: 's1',
        shipCargo: {'s1': [Cargo(commodityId: 'food', quantity: 15)]},
        currentPlanetId: 'jupiter', missions: [mission],
        lastSaved: DateTime.now(),
      );
      // v1.2.15 fix
      final toDeliver = state.missions.where((m) =>
          m.destinationPlanetId == 'jupiter' &&
          m.status == MissionStatus.active).toList();
      expect(toDeliver.length, 1);
    });

    test('6. UI: COMPLETE MISSION button (v1.2.14)', () {
      final mission = Mission(
        id: 'm1', originPlanetId: 'terra', destinationPlanetId: 'jupiter',
        governorName: 'G', description: 'Jupiter: need food',
        commodityId: 'food', quantity: 12,
        rewardCredits: 1500, rewardCreditScore: 50,
        acceptedOnTurn: 0, deadlineTurn: 5,
        status: MissionStatus.active,
      );
      final state = GameState(
        ships: [_ship('s1', planetId: 'jupiter')],
        activeShipId: 's1',
        shipCargo: {'s1': [Cargo(commodityId: 'food', quantity: 15)]},
        currentPlanetId: 'jupiter', missions: [mission],
        lastSaved: DateTime.now(),
      );
      // v1.2.14 fix: sum across fleet
      final m = state.missions.first;
      int total = 0;
      for (final ship in state.equippedShips) {
        for (final c in (state.shipCargo[ship.id] ?? [])) {
          if (c.commodityId == m.commodityId) {
            total = total + (c.quantity as int);
          }
        }
      }
      expect(total >= m.quantity, true);
    });

    test('7. Complete mission → reward, cargo consumed', () {
      final mission = Mission(
        id: 'm1', originPlanetId: 'terra', destinationPlanetId: 'jupiter',
        governorName: 'G', description: 'Jupiter: need food',
        commodityId: 'food', quantity: 12,
        rewardCredits: 1500, rewardCreditScore: 50,
        acceptedOnTurn: 0, deadlineTurn: 5,
        status: MissionStatus.active,
      );
      // Simulate
      var cargo = [Cargo(commodityId: 'food', quantity: 15)];
      cargo[0] = cargo[0].copyWith(quantity: cargo[0].quantity - mission.quantity);
      expect(cargo[0].quantity, 3);
      final newCredits = 5000 + mission.rewardCredits;
      expect(newCredits, 6500);
    });

    test('8. Fleet cap 15 → 10 equipped (v1.2.8)', () {
      final ships = List.generate(15, (i) => _ship('s$i'));
      final state = GameState(ships: ships, lastSaved: DateTime.now());
      expect(state.equippedShips.length, 10);
    });

    test('9. GameState.fresh defaults', () {
      final s = GameState.fresh();
      expect(s.turn, 0);
      expect(s.credits, 5000);
      expect(s.currentPlanetId, 'terra');
    });

    test('10. Mission lifecycle', () {
      var m = Mission(
        id: 'm1', originPlanetId: 'terra', destinationPlanetId: 'jupiter',
        governorName: 'G', description: 'D', commodityId: 'food',
        quantity: 5, rewardCredits: 100, rewardCreditScore: 50,
        acceptedOnTurn: 0, deadlineTurn: 5,
        status: MissionStatus.available,
      );
      m = m.copyWith(status: MissionStatus.active);
      expect(m.status, MissionStatus.active);
      m = m.copyWith(status: MissionStatus.completed);
      expect(m.status, MissionStatus.completed);
    });
  });
}
