import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/models/game_state.dart';
import 'package:space_traders/models/ship.dart';

Ship _ship(String id, {bool equipped = true, String? planetId}) => Ship(
  id: id,
  typeId: 'scout',
  name: 'Scout',
  baseCargo: 20,
  cargoUpgradeBonus: 0,
  baseWeapons: 1,
  weaponUpgradeBonus: 0,
  price: 0,
  cargoUpgradeCost: 800,
  weaponUpgradeCost: 1000,
  speed: 1.0,
  sprite: 'scout',
  equipped: equipped,
  currentPlanetId: planetId,
);

void main() {
  group('equippedShips cap', () {
    test('caps at 10 even when state has 12 equipped (corruption heal)', () {
      final ships = List.generate(12, (i) => _ship('ship_$i'));
      final state = GameState(ships: ships, lastSaved: DateTime.now());
      expect(state.equippedShips.length, 10,
          reason: 'must cap at maxShipsEquipped (10) even with corruption');
    });

    test('returns exactly 10 when state has 10 equipped', () {
      final ships = List.generate(10, (i) => _ship('ship_$i'));
      final state = GameState(ships: ships, lastSaved: DateTime.now());
      expect(state.equippedShips.length, 10);
    });

    test('returns 5 when state has 5 equipped (normal case)', () {
      final ships = List.generate(5, (i) => _ship('ship_$i'));
      final state = GameState(ships: ships, lastSaved: DateTime.now());
      expect(state.equippedShips.length, 5);
    });

    test('returns 0 when no ships are equipped', () {
      final ships = List.generate(3, (i) => _ship('ship_$i', equipped: false));
      final state = GameState(ships: ships, lastSaved: DateTime.now());
      expect(state.equippedShips.length, 0);
    });
  });
}
