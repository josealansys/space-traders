import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/systems/trading/trading_system.dart';
import 'package:space_traders/models/planet.dart';
import 'package:space_traders/models/commodity.dart';

Planet _testPlanet(String id) => Planet(
      id: id,
      name: id,
      description: 'test planet',
      color: const Color(0xFF000000),
      accentColor: const Color(0xFF000000),
      size: 1.0,
      governmentType: GovernmentType.federalDemocracy,
      lawLevel: LawLevel.strict,
      taxRate: 0.05,
      specialties: const ['food'],
      basePrices: const {
        'food': 50,
        'water': 30,
        'fuel': 100,
        'ore': 80,
      },
      travelCost: 50,
      bankName: 'Test Bank',
      governorName: 'Test Gov',
      shipyardTier: 3,
    );

Commodity _testCommodity(String id) => Commodity(
      id: id,
      name: id,
      icon: id,
      basePrice: 50,
      category: 'essential',
      description: 'test commodity',
      volatility: 0.15,
    );

void main() {
  group('TradingSystem price stability (v1.2.2 fix)', () {
    test('calculatePrice returns same value across 100 calls when cache is populated',
        () {
      // THE BUG: prices changed on every render.
      // THE FIX: prices are cached and only re-roll on travel.
      final trading = TradingSystem(rng: Random(42));
      final planet = _testPlanet('terra');
      final commodity = _testCommodity('food');

      final initial = trading.rollPricesForPlanet(
        planet: planet,
        commodities: [commodity],
        currentTurn: 0,
        existingModifiers: const {},
        existingLastRollTurn: const {},
        existingCachedPrices: const {},
      );

      final p1 = trading.calculatePrice(
        planet: planet,
        commodity: commodity,
        currentTurn: 0,
        modifiers: initial.modifiers,
        lastRollTurn: initial.lastRollTurn,
        cachedPrices: initial.cachedPrices,
      );

      for (int i = 0; i < 100; i++) {
        final p = trading.calculatePrice(
          planet: planet,
          commodity: commodity,
          currentTurn: 0,
          modifiers: initial.modifiers,
          lastRollTurn: initial.lastRollTurn,
          cachedPrices: initial.cachedPrices,
        );
        expect(
          p.currentPrice,
          equals(p1.currentPrice),
          reason: 'Price must be stable per turn (user-reported bug fix)',
        );
      }
    });

    test('rollPricesForPlanet rolls some commodities across many seeds', () {
      final planet = _testPlanet('jupiter');
      final commodities = ['food', 'water', 'fuel', 'ore']
          .map(_testCommodity)
          .toList();

      int seedsWithRolls = 0;
      for (int seed = 0; seed < 50; seed++) {
        final trading = TradingSystem(rng: Random(seed));
        final rolled = trading.rollPricesForPlanet(
          planet: planet,
          commodities: commodities,
          currentTurn: 0,
          existingModifiers: const {},
          existingLastRollTurn: const {},
          existingCachedPrices: const {},
        );
        if (rolled.cachedPrices.isNotEmpty) seedsWithRolls++;
      }
      // With 4 commodities at 50% each, P(at least 1) = 1 - 0.5^4 = 93.75%
      expect(
        seedsWithRolls,
        greaterThan(30),
        reason: '~93% of seeds should produce at least 1 roll',
      );
    });

    test('rollPricesForPlanet does not roll all commodities (some stay same)', () {
      // User's requirement: "might change it might not"
      // So on a single roll, not all 9 commodities should change.
      final planet = _testPlanet('jupiter');
      final commodities = [
        'food',
        'water',
        'fuel',
        'ore',
        'electronics',
        'medicine',
        'luxury',
        'tech',
        'contraband',
      ]
          .map(_testCommodity)
          .toList();

      final trading = TradingSystem(rng: Random(7));
      final rolled = trading.rollPricesForPlanet(
        planet: planet,
        commodities: commodities,
        currentTurn: 0,
        existingModifiers: const {},
        existingLastRollTurn: const {},
        existingCachedPrices: const {},
      );

      // Some rolled, some didn't (cached map should have < 9 entries)
      expect(rolled.cachedPrices.length, lessThan(9),
          reason: 'Per user spec: "might change, might not" — not all should roll');
      expect(rolled.cachedPrices.length, greaterThan(0),
          reason: 'At least one should change per travel');
    });
  });
}
