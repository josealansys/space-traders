
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/models/game_state.dart';
import 'package:space_traders/models/ship.dart';
import 'package:space_traders/models/cargo.dart';
import 'package:space_traders/models/mission.dart';

Ship _ship(String id, {bool equipped = true, String? planetId, int cargo = 20}) => Ship(
  id: id, typeId: 'scout', name: 'Scout',
  baseCargo: cargo, cargoUpgradeBonus: 0, baseWeapons: 1, weaponUpgradeBonus: 0,
  price: 0, cargoUpgradeCost: 800, weaponUpgradeCost: 1000, speed: 1.0,
  sprite: 'scout', equipped: equipped, currentPlanetId: planetId,
);

void main() {
  group('Critical flow: avg cost basis', () {
    test('avg cost is null when never bought', () {
      final state = GameState(lastSaved: DateTime.now());
      expect(state.avgCostPerUnit('food'), isNull);
    });

    test('avg cost reflects total spent / total bought', () {
      // Bought 10 food at 50cr + 10 food at 60cr = 1100cr total for 20 units
      // avg = 55cr
      final state = GameState(
        lastSaved: DateTime.now(),
        totalCostByCommodity: {'food': 1100},
        totalBoughtByCommodity: {'food': 20},
      );
      expect(state.avgCostPerUnit('food'), 55);
    });

    test('avg cost with multiple commodities isolated', () {
      final state = GameState(
        lastSaved: DateTime.now(),
        totalCostByCommodity: {'food': 500, 'water': 300},
        totalBoughtByCommodity: {'food': 10, 'water': 30},
      );
      expect(state.avgCostPerUnit('food'), 50);  // 500/10
      expect(state.avgCostPerUnit('water'), 10);  // 300/30
    });
  });

  group('Critical flow: fleet cap (defensive)', () {
    test('13 equipped ships → getter returns 10', () {
      final ships = List.generate(13, (i) => _ship('ship_$i'));
      final state = GameState(ships: ships, lastSaved: DateTime.now());
      expect(state.equippedShips.length, 10);
    });

    test('5 equipped + 5 stored = 5 equipped from getter', () {
      final ships = [
        ...List.generate(5, (i) => _ship('ship_$i', equipped: true)),
        ...List.generate(5, (i) => _ship('stored_$i', equipped: false)),
      ];
      final state = GameState(ships: ships, lastSaved: DateTime.now());
      expect(state.equippedShips.length, 5);
      expect(state.storedShips.length, 5);
    });
  });

  group('Critical flow: mission data integrity', () {
    test('Mission has origin and destination different from each other', () {
      final m = Mission(
        id: 'test', originPlanetId: 'terra', destinationPlanetId: 'jupiter',
        governorName: 'A', description: 'D', commodityId: 'food',
        quantity: 5, rewardCredits: 100, rewardCreditScore: 50,
        acceptedOnTurn: 0, deadlineTurn: 5,
      );
      expect(m.originPlanetId, 'terra');
      expect(m.destinationPlanetId, 'jupiter');
      expect(m.originPlanetId, isNot(equals(m.destinationPlanetId)));
    });

    test('Mission turnsUntilDeadline calculation', () {
      final m = Mission(
        id: 'test', originPlanetId: 'a', destinationPlanetId: 'b',
        governorName: 'A', description: 'D', commodityId: 'food',
        quantity: 5, rewardCredits: 100, rewardCreditScore: 50,
        acceptedOnTurn: 0, deadlineTurn: 5,
      );
      expect(m.turnsUntilDeadline(0), 5);
      expect(m.turnsUntilDeadline(3), 2);
      expect(m.turnsUntilDeadline(6), -1); // overdue
    });
  });

  group('Critical flow: cargo across fleet', () {
    test('sum of fleet cargo = total across ships', () {
      final state = GameState(
        ships: [_ship('a'), _ship('b'), _ship('c')],
        shipCargo: {
          'a': [Cargo(commodityId: 'food', quantity: 5)],
          'b': [Cargo(commodityId: 'food', quantity: 3)],
          'c': [Cargo(commodityId: 'food', quantity: 2)],
        },
        lastSaved: DateTime.now(),
      );
      // All 3 ships equipped, total = 5+3+2 = 10
      int total = 0;
      for (final ship in state.equippedShips) {
        final c = state.shipCargo[ship.id] ?? [];
        for (final cargo in c) {
          total += cargo.quantity;
        }
      }
      expect(total, 10);
    });
  });
}
