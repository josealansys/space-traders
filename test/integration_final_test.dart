
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/data/data_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('INTEGRATION: Real data verification', () {
    test('1. All 9 commodities present in JSON', () async {
      final raw = await DataLoader.loadCommodities();
      expect(raw.length, 9);
      final ids = raw.map((m) => m['id'] as String).toSet();
      for (final expected in ['food', 'water', 'fuel', 'ore',
                               'electronics', 'medicine', 'luxury',
                               'tech', 'contraband']) {
        expect(ids.contains(expected), true, reason: 'Missing: $expected');
      }
    });

    test('2. All 9 planets present in JSON', () async {
      final raw = await DataLoader.loadPlanets();
      expect(raw.length, 9);
      final ids = raw.map((m) => m['id'] as String).toSet();
      for (final expected in ['terra', 'mars', 'jupiter', 'saturn',
                               'venus', 'mercury', 'neptune', 'io', 'titan']) {
        expect(ids.contains(expected), true, reason: 'Missing: $expected');
      }
    });

    test('3. Every planet has all 9 commodity prices', () async {
      final planets = await DataLoader.loadPlanets();
      final commodities = await DataLoader.loadCommodities();
      final cids = commodities.map((m) => m['id'] as String).toSet();
      for (final p in planets) {
        final prices = (p['basePrices'] as Map?)?.cast<String, int>() ?? {};
        for (final cid in cids) {
          expect(prices.containsKey(cid), true,
            reason: '${p['id']} missing $cid');
        }
      }
    });

    test('4. Trade routes exist (price gaps per commodity)', () async {
      final planets = await DataLoader.loadPlanets();
      final commodities = await DataLoader.loadCommodities();
      for (final c in commodities) {
        final cid = c['id'] as String;
        var minPrice = 999999;
        var maxPrice = 0;
        for (final p in planets) {
          final prices = (p['basePrices'] as Map?)?.cast<String, int>() ?? {};
          final price = prices[cid] ?? 0;
          if (price < minPrice) minPrice = price;
          if (price > maxPrice) maxPrice = price;
        }
        expect(maxPrice, greaterThan(minPrice),
          reason: '$cid: no price gap');
      }
    });

    test('5. Design doc trade routes are real', () async {
      final planets = await DataLoader.loadPlanets();
      int price(String planetId, String commodityId) {
        final p = planets.firstWhere((p) => p['id'] == planetId);
        final prices = (p['basePrices'] as Map?)?.cast<String, int>() ?? {};
        return prices[commodityId] ?? 0;
      }
      // Water: Jupiter (15) → Neptune (48)
      expect(price('jupiter', 'water'), 15);
      expect(price('neptune', 'water'), 48);
      // Food: Saturn (20) → Jupiter (95)
      expect(price('saturn', 'food'), 20);
      expect(price('jupiter', 'food'), 95);
      // Luxury: Venus < Mars
      expect(price('venus', 'luxury'), lessThan(price('mars', 'luxury')));
    });
  });
}
