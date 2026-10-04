import 'dart:math';
import '../../models/planet.dart';
import '../../models/commodity.dart';
import '../../config/game_config.dart';

/// Market price tier for a commodity on a planet.
enum PriceTier {
  surplus,  // < 60% of base
  low,      // 60-85%
  normal,   // 85-115%
  high,     // 115-150%
  premium,  // > 150%
}

/// A current market price with tier info.
class MarketPrice {
  final int currentPrice;
  final int basePrice;
  final PriceTier tier;
  final double percentOfBase;
  final int lastRollTurn;

  const MarketPrice({
    required this.currentPrice,
    required this.basePrice,
    required this.tier,
    required this.percentOfBase,
    required this.lastRollTurn,
  });

  /// Stock icon character for this tier.
  String get stockIcon {
    switch (tier) {
      case PriceTier.surplus: return '🔥';
      case PriceTier.low: return '📈';
      case PriceTier.normal: return '➖';
      case PriceTier.high: return '📉';
      case PriceTier.premium: return '💎';
    }
  }

  /// Human-readable tier label.
  String get tierLabel {
    switch (tier) {
      case PriceTier.surplus: return 'SURPLUS';
      case PriceTier.low: return 'LOW';
      case PriceTier.normal: return 'NORMAL';
      case PriceTier.high: return 'HIGH';
      case PriceTier.premium: return 'PREMIUM';
    }
  }
}

/// Trading system: handles price calculations and rolls.
class TradingSystem {
  final Random _rng;

  TradingSystem({Random? rng}) : _rng = rng ?? Random();

  /// Compose a key for price modifier lookups.
  static String priceKey(String planetId, String commodityId) =>
      '$planetId:$commodityId';

  /// Calculate the current market price for a commodity on a planet.
  ///
  /// Uses stored modifier if recent; otherwise rolls a new one
  /// (at least every 3 turns).
  MarketPrice calculatePrice({
    required Planet planet,
    required Commodity commodity,
    required int currentTurn,
    required Map<String, double> modifiers,
    required Map<String, int> lastRollTurn,
  }) {
    final key = priceKey(planet.id, commodity.id);
    final lastRoll = lastRollTurn[key] ?? -999;
    final turnsSinceRoll = currentTurn - lastRoll;

    double modifier = modifiers[key] ?? 1.0;

    // Roll new modifier if never rolled or every 3+ turns
    if (lastRoll < 0 || turnsSinceRoll >= GameConfig.priceRerollInterval) {
      final variance = (commodity.volatility + GameConfig.priceVolatility) / 2;
      modifier = 1.0 + (_rng.nextDouble() * 2 - 1) * variance;
    }

    final basePrice = planet.basePrices[commodity.id] ?? commodity.basePrice;
    final rawPrice = (basePrice * modifier).round();
    final percent = rawPrice / basePrice;

    PriceTier tier;
    if (percent < 0.60) {
      tier = PriceTier.surplus;
    } else if (percent < 0.85) {
      tier = PriceTier.low;
    } else if (percent < 1.15) {
      tier = PriceTier.normal;
    } else if (percent < 1.50) {
      tier = PriceTier.high;
    } else {
      tier = PriceTier.premium;
    }

    return MarketPrice(
      currentPrice: rawPrice,
      basePrice: basePrice,
      tier: tier,
      percentOfBase: percent,
      lastRollTurn: lastRoll,
    );
  }

  /// Roll all prices for all commodities on all planets.
  /// Returns updated modifier maps.
  ({Map<String, double> modifiers, Map<String, int> lastRollTurn}) rollAllPrices({
    required List<Planet> planets,
    required List<Commodity> commodities,
    required int currentTurn,
    required Map<String, double> existingModifiers,
    required Map<String, int> existingLastRoll,
  }) {
    final newModifiers = Map<String, double>.from(existingModifiers);
    final newLastRoll = Map<String, int>.from(existingLastRoll);

    for (final planet in planets) {
      for (final commodity in commodities) {
        final key = priceKey(planet.id, commodity.id);
        final lastRoll = existingLastRoll[key] ?? -999;
        final turnsSince = currentTurn - lastRoll;

        // Roll if never rolled or interval elapsed
        if (lastRoll < 0 || turnsSince >= GameConfig.priceRerollInterval) {
          final variance = (commodity.volatility + GameConfig.priceVolatility) / 2;
          final modifier = 1.0 + (_rng.nextDouble() * 2 - 1) * variance;
          newModifiers[key] = modifier;
          newLastRoll[key] = currentTurn;
        }
      }
    }

    return (modifiers: newModifiers, lastRollTurn: newLastRoll);
  }
}
