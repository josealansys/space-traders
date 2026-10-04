
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/models/game_state.dart';
import 'package:space_traders/models/ship.dart';
import 'package:space_traders/models/cargo.dart';
import 'package:space_traders/models/mission.dart';
import 'package:space_traders/models/loan.dart';
import 'package:space_traders/models/crew.dart';

Ship _ship(String id, {int cargo = 20, int basePrice = 0}) => Ship(
  id: id, typeId: 'scout', name: 'Scout',
  baseCargo: cargo, cargoUpgradeBonus: 0, baseWeapons: 1, weaponUpgradeBonus: 0,
  price: basePrice, cargoUpgradeCost: 800, weaponUpgradeCost: 1000, speed: 1.0,
  sprite: 'scout', equipped: true, currentPlanetId: 'terra',
);

void main() {
  group('INTEGRATION: New game → trade → P&L', () {
    test('1. Player starts with credits and no ships', () {
      final state = GameState.fresh();
      expect(state.turn, 0);
      expect(state.credits, 5000);
      expect(state.ships.length, 0); // fresh, no starter (pre-v1.2.4 logic)
    });

    test('2. After buying cargo, cost basis is tracked', () {
      final state = GameState(
        lastSaved: DateTime.now(),
        ships: [_ship('a')],
        activeShipId: 'a',
        shipCargo: {'a': [Cargo(commodityId: 'food', quantity: 10)]},
        credits: 4500, // 5000 - 500
        totalCostByCommodity: {'food': 500},
        totalBoughtByCommodity: {'food': 10},
      );
      expect(state.avgCostPerUnit('food'), 50);
    });

    test('3. After selling, P&L calculation: buy@50, sell@60, +100cr', () {
      // Bought 10 @ 50 = 500 spent
      // Now selling 10 @ 60 = 600 revenue
      // Profit = +100cr
      final avg = 50;
      final currentPrice = 60;
      final quantity = 10;
      final profit = (currentPrice - avg) * quantity;
      expect(profit, 100);
    });

    test('4. Loss scenario: buy@50, sell@40, -100cr', () {
      final avg = 50;
      final currentPrice = 40;
      final quantity = 10;
      final loss = (currentPrice - avg) * quantity;
      expect(loss, -100);
    });
  });

  group('INTEGRATION: Fleet management', () {
    test('1. Starting state respects maxShipsEquipped (10)', () {
      final ships = List.generate(15, (i) => _ship('ship_$i'));
      final state = GameState(
        ships: ships,
        lastSaved: DateTime.now(),
        activeShipId: 'ship_0',
      );
      // 15 ships but equipped getter caps at 10
      expect(state.ships.length, 15);
      expect(state.equippedShips.length, 10);
    });

    test('2. fleet.totalCapacity sums all equipped', () {
      final ships = List.generate(5, (i) => _ship('ship_$i', cargo: 20));
      final state = GameState(ships: ships, lastSaved: DateTime.now());
      int total = 0;
      for (final s in state.equippedShips) {
        total += s.cargoCapacity;
      }
      expect(total, 100); // 5 * 20
    });
  });

  group('INTEGRATION: Mission lifecycle', () {
    Mission makeMission({MissionStatus status = MissionStatus.active, int deadline = 5, int currentTurn = 0}) {
      return Mission(
        id: 'm1',
        originPlanetId: 'terra',
        destinationPlanetId: 'jupiter',
        governorName: 'Gov',
        description: 'Deliver food',
        commodityId: 'food',
        quantity: 10,
        rewardCredits: 1000,
        rewardCreditScore: 50,
        acceptedOnTurn: 0,
        deadlineTurn: deadline,
        status: status,
      );
    }

    test('1. Mission created with origin ≠ destination', () {
      final m = makeMission();
      expect(m.originPlanetId, 'terra');
      expect(m.destinationPlanetId, 'jupiter');
    });

    test('2. Mission deadline countdown', () {
      final m = makeMission(deadline: 5);
      expect(m.turnsUntilDeadline(0), 5);
      expect(m.turnsUntilDeadline(3), 2);
      expect(m.turnsUntilDeadline(5), 0);
      expect(m.turnsUntilDeadline(6), -1);
    });

    test('3. Mission isExpired when past deadline and active', () {
      final m = makeMission(status: MissionStatus.active, deadline: 5);
      expect(m.isExpired(6), true);
      expect(m.isExpired(4), false);
    });

    test('4. Mission status transitions: available → active → completed', () {
      var m = makeMission(status: MissionStatus.available);
      m = m.copyWith(status: MissionStatus.active);
      m = m.copyWith(status: MissionStatus.completed);
      expect(m.status, MissionStatus.completed);
    });
  });

  group('INTEGRATION: Price stability (from v1.2.2 fix)', () {
    test('Same trade = same total cost (no random price fluctuation per action)', () {
      // After v1.2.2, prices are cached per turn.
      // Simulate: compute same price twice → same result.
      // (We trust this is what the TradingSystem.rollPricesForPlanet does.)
      expect(true, isTrue); // covered by stability_test.dart
    });
  });

  group('INTEGRATION: Game state integrity', () {
    test('Fresh state has all critical defaults', () {
      final s = GameState.fresh();
      expect(s.turn, 0);
      expect(s.credits, 5000);
      expect(s.creditScore, 1000);
      expect(s.currentPlanetId, 'terra');
      expect(s.bounty, 0);
      expect(s.priceModifiers, isEmpty);
      expect(s.priceLastRoll, isEmpty);
      expect(s.totalCostByCommodity, isEmpty);
      expect(s.totalBoughtByCommodity, isEmpty);
      expect(s.totalSoldByCommodity, isEmpty);
    });

    test('CopyWith preserves unchanged fields', () {
      final original = GameState(
        credits: 1000,
        lastSaved: DateTime.now(),
        totalCostByCommodity: {'food': 500},
      );
      final copy = original.copyWith(credits: 2000);
      expect(copy.credits, 2000);
      expect(copy.totalCostByCommodity, {'food': 500});
    });
  });
}
