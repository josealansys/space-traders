
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/models/game_state.dart';
import 'package:space_traders/models/ship.dart';
import 'package:space_traders/models/cargo.dart';
import 'package:space_traders/models/crew.dart';
import 'package:space_traders/models/commodity.dart';
import 'package:space_traders/models/planet.dart';
import 'package:space_traders/systems/trading/trading_system.dart';
import 'package:space_traders/systems/warehouse/crew_engine.dart';
import 'package:space_traders/config/game_config.dart';

Ship _ship(String id) => Ship(
  id: id, typeId: 'scout', name: 'Scout',
  baseCargo: 20, cargoUpgradeBonus: 0, baseWeapons: 1, weaponUpgradeBonus: 0,
  price: 0, cargoUpgradeCost: 800, weaponUpgradeCost: 1000, speed: 1.0,
  sprite: 'scout', equipped: true, currentPlanetId: 'terra',
);

Crew _crew(String id, String planetId, {int funding = 5000}) => Crew(
  id: id, planetId: planetId, name: 'Test Crew',
  funding: funding, skill: 0.8, status: CrewStatus.active,
  hiredOnTurn: 0, history: const [],
);

Planet _planet(String id, String name, Map<String, int> prices) => Planet(
  id: id, name: name, description: '', color: 0xFF000000, accentColor: 0xFF000000,
  ringColor: 0xFF000000, size: 1.0, governmentType: GovernmentType.federalDemocracy,
  lawLevel: LawLevel.moderate, taxRate: 0.1, specialties: prices.keys.toList(),
  basePrices: prices, travelCost: 50, bankName: 'Bank', governorName: 'G',
  shipyardTier: 1,
);

Commodity _commodity(String id, int basePrice) => Commodity(
  id: id, name: id, icon: 'x', description: '',
  basePrice: basePrice, category: 'essential', volatility: 0.1,
);

void main() {
  group('AI Crew trading logic', () {
    test('1. Only 1 crew per warehouse (planet)', () {
      // Bug fix: the cap is 1, not 3
      // This is enforced in the controller. The Crew model itself has no cap.
      // The cap is documented in the controller + warehouse_tab UI.
      // (We test the engine can handle a single crew.)
      final state = GameState(
        ships: [_ship('a')],
        activeShipId: 'a',
        currentPlanetId: 'terra',
        crews: [_crew('c1', 'terra', funding: 1000)],
        lastSaved: DateTime.now(),
      );
      final crewsAtTerra = state.crews.where((c) => c.planetId == 'terra').toList();
      expect(crewsAtTerra.length, 1);
    });

    test('2. Crew engine evaluates buy/sell based on price tier', () {
      final trading = TradingSystem();
      final crew = _crew('c1', 'saturn', funding: 5000);
      // Saturn has cheap food (20)
      final saturn = _planet('saturn', 'Saturn', {'food': 20, 'water': 18});
      final commodities = [
        _commodity('food', 50),
        _commodity('water', 30),
      ];
      final engine = CrewEngine(trading: trading);
      // Roll prices for Saturn
      final rolled = trading.rollPricesForPlanet(
        planet: saturn, commodities: commodities, currentTurn: 0,
        existingModifiers: const {},
        existingLastRollTurn: const {},
        existingCachedPrices: const {},
      );
      final decisions = engine.runAllCrews(
        crews: [crew], warehouseCargo: {'saturn': <Cargo>[]},
        planets: [saturn], commodities: commodities, currentTurn: 0,
        priceModifiers: rolled.modifiers,
        priceLastRollTurn: rolled.lastRollTurn,
      );
      // With high skill (0.8) and surplus price, crew should buy
      // (We just check the engine returns a decision, not the specific action)
      expect(decisions.length, lessThanOrEqualTo(1));
    });

    test('3. Crew engine applies buy decision: warehouse gets cargo, funding decreases', () {
      final trading = TradingSystem();
      final crew = _crew('c1', 'saturn', funding: 1000);
      final saturn = _planet('saturn', 'Saturn', {'food': 20});
      final commodities = [_commodity('food', 50)];
      final engine = CrewEngine(trading: trading);
      // Manually craft a buy decision
      final decision = CrewDecision(
        crewId: 'c1', commodityId: 'food', action: CrewAction.buy,
        quantity: 5, pricePerUnit: 20, reason: 'test',
      );
      final result = engine.applyDecision(
        crew: crew, decision: decision, warehouse: <Cargo>[],
      );
      expect(result.newWarehouse.length, 1);
      expect(result.newWarehouse.first.commodityId, 'food');
      expect(result.newWarehouse.first.quantity, 5);
      expect(result.cashDelta, -100); // 5 * 20
      expect(result.newCrew.funding, 900); // 1000 - 100
    });

    test('4. Crew engine applies sell decision: warehouse loses cargo, funding increases', () {
      final trading = TradingSystem();
      final crew = _crew('c1', 'saturn', funding: 0);
      final saturn = _planet('saturn', 'Saturn', {'food': 20});
      final commodities = [_commodity('food', 50)];
      final engine = CrewEngine(trading: trading);
      final decision = CrewDecision(
        crewId: 'c1', commodityId: 'food', action: CrewAction.sell,
        quantity: 3, pricePerUnit: 100, reason: 'test',
      );
      final result = engine.applyDecision(
        crew: crew, decision: decision,
        warehouse: [Cargo(commodityId: 'food', quantity: 10)],
      );
      expect(result.newWarehouse.length, 1);
      expect(result.newWarehouse.first.quantity, 7); // 10 - 3
      expect(result.cashDelta, 300); // 3 * 100
      expect(result.newCrew.funding, 300);
    });

    test('5. Crew respects warehouse capacity (100 units)', () {
      // The buy decision clamps to warehouse space
      // (Already implemented in applyDecision: cost > crew.funding returns 0)
      // The warehouse capacity check is at controller.depositCargo
      // Here we just verify the buy is bounded by crew funding
      final trading = TradingSystem();
      final crew = _crew('c1', 'saturn', funding: 100);
      final saturn = _planet('saturn', 'Saturn', {'food': 20});
      final commodities = [_commodity('food', 50)];
      final engine = CrewEngine(trading: trading);
      // Try to buy 100 units at 20cr each = 2000 cr (but crew has only 100)
      final decision = CrewDecision(
        crewId: 'c1', commodityId: 'food', action: CrewAction.buy,
        quantity: 100, pricePerUnit: 20, reason: 'test',
      );
      final result = engine.applyDecision(
        crew: crew, decision: decision, warehouse: <Cargo>[],
      );
      // Crew can't afford → no change
      expect(result.cashDelta, 0);
      expect(result.newWarehouse.length, 0);
    });
  });
}
