
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/models/planet.dart';
import 'package:space_traders/models/commodity.dart';
import 'package:space_traders/models/cargo.dart';
import 'package:space_traders/models/crew.dart';
import 'package:space_traders/systems/trading/trading_system.dart';
import 'package:space_traders/systems/warehouse/crew_engine.dart';
import 'package:space_traders/config/game_config.dart';

Planet _planet(String id, String name, Map<String, int> prices) => Planet(
  id: id, name: name, description: '', color: const Color(0xFF000000),
  accentColor: const Color(0xFF000000), ringColor: const Color(0xFF000000),
  size: 1.0, governmentType: GovernmentType.federalDemocracy,
  lawLevel: LawLevel.moderate, taxRate: 0.1, specialties: prices.keys.toList(),
  basePrices: prices, travelCost: 50, bankName: 'Bank',
  governorName: 'G', shipyardTier: 1,
);

Commodity _commodity(String id, int basePrice) => Commodity(
  id: id, name: id, icon: 'x', description: '',
  basePrice: basePrice, category: 'essential', volatility: 0.1,
);

Crew _crew(String id, String planetId, {int funding = 10000, double skill = 0.8}) => Crew(
  id: id, planetId: planetId, name: 'Test',
  funding: funding, skill: skill, status: CrewStatus.active,
  hiredOnTurn: 0, history: const [],
);

void main() {
  // Reproduce the EXACT logic step by step to see why the crew doesn't buy
  group('DEBUG: Why is crew not buying cheap cargo?', () {
    test('Step 1: Saturn food price is 20cr (base 50 = 40% of base)', () {
      // Saturn food base price = 50, planet-specific = 20
      // So Saturn food is CHEAP at 40% of base
      final saturn = _planet('saturn', 'Saturn', {'food': 20, 'water': 18});
      // After a price roll (which adds ±20% volatility):
      // Could be 16-24cr per unit
      // Both 16 and 24 are well below base 50
      // → Should trigger BUY
      print('Saturn food base: ${saturn.basePrices['food']}cr, base commodity: 50cr');
      print('This is 40% of base, should be SURPLUS tier');
    });

    test('Step 2: Test price tier calculation with low price', () {
      final trading = TradingSystem();
      final saturn = _planet('saturn', 'Saturn', {'food': 20});
      final food = _commodity('food', 50);
      // No modifiers yet (first turn)
      // Roll prices
      final rolled = trading.rollPricesForPlanet(
        planet: saturn, commodities: [food], currentTurn: 0,
        existingModifiers: const {},
        existingLastRollTurn: const {},
        existingCachedPrices: const {},
      );
      print('After roll, price modifiers: ${rolled.modifiers}');
      print('After roll, lastRollTurn: ${rolled.lastRollTurn}');
      print('After roll, cached prices: ${rolled.cachedPrices}');
      // Get price
      final price = trading.calculatePrice(
        planet: saturn, commodity: food, currentTurn: 0,
        modifiers: rolled.modifiers,
        lastRollTurn: rolled.lastRollTurn,
        cachedPrices: rolled.cachedPrices,
      );
      print('Price: ${price.currentPrice}cr (base 50) → tier: ${price.tierLabel}');
      print('Percent of base: ${(price.percentOfBase * 100).toStringAsFixed(0)}%');
      // The price should be surplus/low
      expect(price.tier.toString(), isNot('normal'));
    });

    test('Step 3: Crew decision with low price', () {
      // Use seeded RNG for determinism
      final trading = TradingSystem();
      // Saturn food = 20
      final saturn = _planet('saturn', 'Saturn', {'food': 20});
      final food = _commodity('food', 50);
      // Crew with high skill
      final crew = _crew('c1', 'saturn', funding: 10000, skill: 0.9);
      // Use runAllCrews via the engine
      final engine = CrewEngine(trading: trading);
      final rolled = trading.rollPricesForPlanet(
        planet: saturn, commodities: [food], currentTurn: 0,
        existingModifiers: const {},
        existingLastRollTurn: const {},
        existingCachedPrices: const {},
      );
      print('Crew funding: ${crew.funding}, skill: ${crew.skill}');
      print('Saturn food price: ${rolled.cachedPrices['saturn:food']}cr');
      // The engine.runAllCrews should return a BUY decision
      final decisions = engine.runAllCrews(
        crews: [crew],
        warehouseCargo: {'saturn': <Cargo>[]},
        planets: [saturn],
        commodities: [food],
        currentTurn: 0,
        priceModifiers: rolled.modifiers,
        priceLastRollTurn: rolled.lastRollTurn,
      );
      print('Decisions made: ${decisions.length}');
      if (decisions.isEmpty) {
        print('  NO DECISIONS - the crew did nothing');
      } else {
        for (final d in decisions) {
          print('  Decision: ${d.action.name} ${d.commodityId} '
              '${d.quantity}u @ ${d.pricePerUnit}cr (${d.reason})');
        }
      }
    });
  });
}
