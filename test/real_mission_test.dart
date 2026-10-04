
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:space_traders/models/planet.dart';
import 'package:space_traders/models/commodity.dart';
import 'package:space_traders/systems/government/government_system.dart';
import 'package:space_traders/data/data_loader.dart';

Planet _parsePlanet(Map<String, dynamic> m) {
  return Planet(
    id: m['id'] as String,
    name: m['name'] as String,
    description: m['description'] as String? ?? '',
    color: Color(m['color'] as int? ?? 0xFF000000),
    accentColor: Color(m['accentColor'] as int? ?? 0xFF000000),
    ringColor: Color(m['ringColor'] as int? ?? 0xFF000000),
    size: (m['size'] as num?)?.toDouble() ?? 1.0,
    governmentType: GovernmentType.values.firstWhere(
      (g) => g.name == m['governmentType'],
      orElse: () => GovernmentType.federalDemocracy,
    ),
    lawLevel: m['lawLevel'] as int? ?? 3,
    taxRate: (m['taxRate'] as num?)?.toDouble() ?? 0.1,
    specialties: ((m['specialties'] as List?) ?? []).map((e) => e as String).toList(),
    basePrices: Map<String, int>.from(
      ((m['basePrices'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, v as int)),
    ),
    travelCost: m['travelCost'] as int? ?? 50,
    bankName: m['bankName'] as String? ?? 'Bank',
    governorName: m['governorName'] as String? ?? 'Governor',
    shipyardTier: m['shipyardTier'] as int? ?? 1,
  );
}

Commodity _parseCommodity(Map<String, dynamic> m) {
  return Commodity(
    id: m['id'] as String,
    name: m['name'] as String,
    icon: m['icon'] as String? ?? '',
    basePrice: m['basePrice'] as int,
    category: CommodityCategory.essential,
  );
}

void main() {
  group('SCENARIO 10: Real data mission generation', () {
    test('10.1 All 9 commodities load correctly', () async {
      final raw = await DataLoader.loadCommodities();
      expect(raw.length, 9);
    });

    test('10.2 All 9 planets load correctly', () async {
      final raw = await DataLoader.loadPlanets();
      expect(raw.length, 9);
    });

    test('10.3 Saturn origin generates valid missions to other planets', () async {
      final planetsRaw = await DataLoader.loadPlanets();
      final commoditiesRaw = await DataLoader.loadCommodities();
      final planets = planetsRaw.map(_parsePlanet).toList();
      final commodities = commoditiesRaw.map(_parseCommodity).toList();
      final saturn = planets.firstWhere((p) => p.id == 'saturn');
      final gov = GovernmentSystem(rng: Random(42));
      final missions = gov.generateMissionsForPlanet(
        originPlanet: saturn,
        commodities: commodities,
        allPlanets: planets,
        currentTurn: 0,
      );
      // Saturn is cheap on water (18) and food (20) → expect missions to other planets
      expect(missions, isNotEmpty, reason: 'Saturn should offer missions to other planets');
      expect(missions.length, lessThanOrEqualTo(3));
      for (final m in missions) {
        expect(m.originPlanetId, 'saturn');
        // All commodities should be ones where Saturn is cheap
        final originPrice = saturn.basePrices[m.commodityId] ?? 999;
        final destPrice = planets
            .firstWhere((p) => p.id == m.destinationPlanetId)
            .basePrices[m.commodityId] ?? 0;
        expect(destPrice, greaterThanOrEqualTo(originPrice),
          reason: 'Dest (${m.destinationPlanetId}: $destPrice) should be ≥ origin (Saturn: $originPrice)');
      }
    });

    test('10.4 Mission descriptions mention destination by name', () async {
      final planetsRaw = await DataLoader.loadPlanets();
      final commoditiesRaw = await DataLoader.loadCommodities();
      final planets = planetsRaw.map(_parsePlanet).toList();
      final commodities = commoditiesRaw.map(_parseCommodity).toList();
      final saturn = planets.firstWhere((p) => p.id == 'saturn');
      final gov = GovernmentSystem(rng: Random(7));
      final missions = gov.generateMissionsForPlanet(
        originPlanet: saturn,
        commodities: commodities,
        allPlanets: planets,
        currentTurn: 0,
      );
      expect(missions, isNotEmpty);
      for (final m in missions) {
        final destPlanet = planets.firstWhere((p) => p.id == m.destinationPlanetId);
        // Description should mention destination name
        expect(m.description, contains(destPlanet.name),
          reason: 'Description should mention destination ${destPlanet.name}');
      }
    });

    test('10.5 Each commodity has a sensible description (not generic)', () async {
      final planetsRaw = await DataLoader.loadPlanets();
      final commoditiesRaw = await DataLoader.loadCommodities();
      final planets = planetsRaw.map(_parsePlanet).toList();
      final commodities = commoditiesRaw.map(_parseCommodity).toList();
      final saturn = planets.firstWhere((p) => p.id == 'saturn');
      final gov = GovernmentSystem(rng: Random(13));
      final missions = gov.generateMissionsForPlanet(
        originPlanet: saturn,
        commodities: commodities,
        allPlanets: planets,
        currentTurn: 0,
      );
      expect(missions, isNotEmpty);
      // Each description should be at least 20 chars and meaningful
      for (final m in missions) {
        expect(m.description.length, greaterThan(20),
          reason: 'Description too short: "${m.description}"');
      }
    });

    test('10.6 All 9 planets can be origin', () async {
      final planetsRaw = await DataLoader.loadPlanets();
      final commoditiesRaw = await DataLoader.loadCommodities();
      final planets = planetsRaw.map(_parsePlanet).toList();
      final commodities = commoditiesRaw.map(_parseCommodity).toList();
      final gov = GovernmentSystem(rng: Random(0));
      for (final origin in planets) {
        final missions = gov.generateMissionsForPlanet(
          originPlanet: origin,
          commodities: commodities,
          allPlanets: planets,
          currentTurn: 0,
        );
        // Each planet should generate 0-3 missions
        expect(missions.length, lessThanOrEqualTo(3),
          reason: '${origin.id} generated too many missions: ${missions.length}');
        // All missions have correct origin
        for (final m in missions) {
          expect(m.originPlanetId, origin.id);
        }
      }
    });
  });
}
