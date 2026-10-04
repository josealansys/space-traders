
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
  // Simulate the exact scenario: mission accepted on Terra, cargo bought on
  // Terra, traveled to Jupiter, checking if UI should show COMPLETE MISSION
  group('DEBUG: Terra origin → Jupiter destination mission flow', () {
    test('1. Initial state after accepting mission on Terra', () {
      // User accepts "Jupiter: need food" mission on Terra
      final mission = Mission(
        id: 'm1',
        originPlanetId: 'terra',           // accepted on Terra
        destinationPlanetId: 'jupiter',    // must deliver to Jupiter
        governorName: 'Gov',
        description: 'Jupiter: facing famine',
        commodityId: 'food',
        quantity: 12,
        rewardCredits: 1500,
        rewardCreditScore: 50,
        acceptedOnTurn: 0,
        deadlineTurn: 5,
        status: MissionStatus.active,
      );
      final state = GameState(
        ships: [_ship('active', planetId: 'terra')],
        activeShipId: 'active',
        currentPlanetId: 'terra',   // player is on Terra
        missions: [mission],
        lastSaved: DateTime.now(),
      );
      expect(state.currentPlanetId, 'terra');
      expect(mission.destinationPlanetId, 'jupiter');
      expect(state.currentPlanetId == mission.destinationPlanetId, false,
        reason: 'player should NOT be at destination yet');
    });

    test('2. Buy cargo on Terra → state has cargo', () {
      // After buying 12 food on Terra
      final state = GameState(
        ships: [_ship('active', planetId: 'terra')],
        activeShipId: 'active',
        shipCargo: {
          'active': [Cargo(commodityId: 'food', quantity: 12)],
        },
        currentPlanetId: 'terra',
        missions: [
          Mission(
            id: 'm1', originPlanetId: 'terra', destinationPlanetId: 'jupiter',
            governorName: 'G', description: 'D', commodityId: 'food',
            quantity: 12, rewardCredits: 1500, rewardCreditScore: 50,
            acceptedOnTurn: 0, deadlineTurn: 5,
            status: MissionStatus.active,
          ),
        ],
        lastSaved: DateTime.now(),
      );
      final c = state.shipCargo['active'] ?? [];
      final food = c.firstWhere((c) => c.commodityId == 'food').quantity;
      expect(food, 12);
    });

    test('3. Travel to Jupiter → cargo travels with ship', () {
      // After travelTo('jupiter')
      final state = GameState(
        ships: [_ship('active', planetId: 'jupiter')], // ship now at jupiter
        activeShipId: 'active',
        shipCargo: {
          'active': [Cargo(commodityId: 'food', quantity: 12)],
        },
        currentPlanetId: 'jupiter',  // player now at jupiter
        missions: [
          Mission(
            id: 'm1', originPlanetId: 'terra', destinationPlanetId: 'jupiter',
            governorName: 'G', description: 'D', commodityId: 'food',
            quantity: 12, rewardCredits: 1500, rewardCreditScore: 50,
            acceptedOnTurn: 0, deadlineTurn: 5,
            status: MissionStatus.active,
          ),
        ],
        lastSaved: DateTime.now(),
      );
      // After travel, ship is at jupiter, cargo is still in ship, player is at jupiter
      expect(state.currentPlanetId, 'jupiter');
      expect(state.ships.first.currentPlanetId, 'jupiter');

      // UI check
      final mission = state.missions.first;
      final isAtDestination = state.currentPlanetId == mission.destinationPlanetId;
      expect(isAtDestination, true, reason: 'Should be at destination');
    });

    test('4. Now UI should show COMPLETE MISSION', () {
      // Reproduce the UI check
      final state = GameState(
        ships: [_ship('active', planetId: 'jupiter')],
        activeShipId: 'active',
        shipCargo: {
          'active': [Cargo(commodityId: 'food', quantity: 12)],
        },
        currentPlanetId: 'jupiter',
        missions: [
          Mission(
            id: 'm1', originPlanetId: 'terra', destinationPlanetId: 'jupiter',
            governorName: 'G', description: 'D', commodityId: 'food',
            quantity: 12, rewardCredits: 1500, rewardCreditScore: 50,
            acceptedOnTurn: 0, deadlineTurn: 5,
            status: MissionStatus.active,
          ),
        ],
        lastSaved: DateTime.now(),
      );
      final mission = state.missions.first;
      // Recompute UI logic
      final isAtDestination = state.currentPlanetId == mission.destinationPlanetId;
      final missionActive = mission.status == MissionStatus.active;

      // Sum cargo across fleet
      int totalOwned = 0;
      for (final ship in state.equippedShips) {
        final c = state.shipCargo[ship.id] ?? [];
        for (final cargo in c) {
          if (cargo.commodityId == mission.commodityId) {
            totalOwned += cargo.quantity;
          }
        }
      }

      final hasCargo = totalOwned >= mission.quantity;
      final canComplete = missionActive && isAtDestination;
      final readyToDeliver = canComplete && hasCargo;

      print('  currentPlanetId: ${state.currentPlanetId}');
      print('  destinationPlanetId: ${mission.destinationPlanetId}');
      print('  isAtDestination: $isAtDestination');
      print('  missionActive: $missionActive');
      print('  totalOwned: $totalOwned');
      print('  mission.quantity: ${mission.quantity}');
      print('  hasCargo: $hasCargo');
      print('  canComplete: $canComplete');
      print('  readyToDeliver: $readyToDeliver');

      expect(readyToDeliver, true, reason: 'COMPLETE MISSION button should appear');
    });
  });
}
