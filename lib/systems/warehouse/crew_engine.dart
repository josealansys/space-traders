import 'dart:math';
import '../../models/crew.dart';
import '../../models/cargo.dart';
import '../../models/planet.dart';
import '../../models/commodity.dart';
import '../../config/game_config.dart';
import '../trading/trading_system.dart';

/// Decision made by an AI crew.
class CrewDecision {
  final String crewId;
  final String commodityId;
  final CrewAction action;
  final int quantity;
  final int pricePerUnit;
  final String reason;
  final bool executed;
  final String? errorMessage;

  const CrewDecision({
    required this.crewId,
    required this.commodityId,
    required this.action,
    required this.quantity,
    required this.pricePerUnit,
    required this.reason,
    this.executed = false,
    this.errorMessage,
  });
}

enum CrewAction { buy, sell, hold, withdraw }

/// AI crew engine — autonomous warehouse trading.
class CrewEngine {
  final Random _rng;
  final TradingSystem _trading;

  CrewEngine({Random? rng, required TradingSystem trading})
      : _rng = rng ?? Random(),
        _trading = trading;

  /// Run all active crews for the current turn.
  ///
  /// Returns the list of decisions made (for logging/UI).
  List<CrewDecision> runAllCrews({
    required List<Crew> crews,
    required Map<String, List<Cargo>> warehouseCargo,
    required List<Planet> planets,
    required List<Commodity> commodities,
    required int currentTurn,
    required Map<String, double> priceModifiers,
    required Map<String, int> priceLastRollTurn,
  }) {
    final decisions = <CrewDecision>[];
    for (final crew in crews) {
      if (crew.status != CrewStatus.active) continue;
      if (crew.funding <= 0) continue;

      final planet = planets.firstWhere(
        (p) => p.id == crew.planetId,
        orElse: () => planets.first,
      );
      final warehouse = warehouseCargo[planet.id] ?? <Cargo>[];

      // Evaluate one trade decision per turn per crew
      final decision = _evaluateAndTrade(
        crew: crew,
        planet: planet,
        warehouse: warehouse,
        commodities: commodities,
        currentTurn: currentTurn,
        priceModifiers: priceModifiers,
        priceLastRollTurn: priceLastRollTurn,
      );
      if (decision != null) {
        decisions.add(decision);
      }
    }
    return decisions;
  }

  /// Evaluate the best trade for one crew and execute it.
  CrewDecision? _evaluateAndTrade({
    required Crew crew,
    required Planet planet,
    required List<Cargo> warehouse,
    required List<Commodity> commodities,
    required int currentTurn,
    required Map<String, double> priceModifiers,
    required Map<String, int> priceLastRollTurn,
  }) {
    // Find best opportunities
    CrewDecision? bestBuy;
    CrewDecision? bestSell;

    for (final commodity in commodities) {
      final price = _trading.calculatePrice(
        planet: planet,
        commodity: commodity,
        currentTurn: currentTurn,
        modifiers: priceModifiers,
        lastRollTurn: priceLastRollTurn,
      );

      // Check if we should BUY (price is surplus/low)
      if (price.tier == PriceTier.surplus || price.tier == PriceTier.low) {
        // Skill affects how aggressively we buy
        final confidence = (price.tier == PriceTier.surplus ? 0.9 : 0.6) * crew.skill;
        if (_rng.nextDouble() < confidence) {
          // Buy up to 30% of available funding
          final maxSpend = (crew.funding * 0.3).round();
          final maxQty = maxSpend ~/ price.currentPrice;
          if (maxQty > 0) {
            final qty = maxQty.clamp(1, 50);
            final candidate = CrewDecision(
              crewId: crew.id,
              commodityId: commodity.id,
              action: CrewAction.buy,
              quantity: qty,
              pricePerUnit: price.currentPrice,
              reason:
                  '${price.tierLabel} price (${(price.percentOfBase * 100 - 100).toStringAsFixed(0)}% vs base)',
            );
            if (bestBuy == null || price.percentOfBase < (bestBuy.pricePerUnit / commodity.basePrice)) {
              bestBuy = candidate;
            }
          }
        }
      }

      // Check if we should SELL (price is high/premium)
      final cargo = warehouse.firstWhere(
        (c) => c.commodityId == commodity.id,
        orElse: () => Cargo(commodityId: commodity.id, quantity: 0),
      );
      if (cargo.quantity > 0 &&
          (price.tier == PriceTier.high || price.tier == PriceTier.premium)) {
        final confidence = (price.tier == PriceTier.premium ? 0.95 : 0.7) * crew.skill;
        if (_rng.nextDouble() < confidence) {
          // Sell up to 50% of holdings
          final qty = (cargo.quantity * 0.5).ceil().clamp(1, cargo.quantity);
          final candidate = CrewDecision(
            crewId: crew.id,
            commodityId: commodity.id,
            action: CrewAction.sell,
            quantity: qty,
            pricePerUnit: price.currentPrice,
            reason:
                '${price.tierLabel} price (${(price.percentOfBase * 100 - 100).toStringAsFixed(0)}% vs base)',
          );
          if (bestSell == null || price.percentOfBase > (bestSell.pricePerUnit / commodity.basePrice)) {
            bestSell = candidate;
          }
        }
      }
    }

    // Prefer sell over buy (lock in profits first)
    return bestSell ?? bestBuy;
  }

  /// Apply a crew decision to the warehouse state.
  /// Returns updated (warehouseCargo, crew) tuple.
  ({List<Cargo> newWarehouse, Crew newCrew, int cashDelta}) applyDecision({
    required Crew crew,
    required CrewDecision decision,
    required List<Cargo> warehouse,
  }) {
    if (decision.action == CrewAction.buy) {
      final cost = decision.quantity * decision.pricePerUnit;
      if (cost > crew.funding) {
        return (
          newWarehouse: warehouse,
          newCrew: crew,
          cashDelta: 0,
        );
      }
      // Add to warehouse
      final newWarehouse = List<Cargo>.from(warehouse);
      final idx = newWarehouse.indexWhere((c) => c.commodityId == decision.commodityId);
      if (idx >= 0) {
        newWarehouse[idx] = newWarehouse[idx].copyWith(
          quantity: newWarehouse[idx].quantity + decision.quantity,
        );
      } else {
        newWarehouse.add(Cargo(commodityId: decision.commodityId, quantity: decision.quantity));
      }
      final newCrew = crew.copyWith(
        funding: crew.funding - cost,
        history: [
          ...crew.history.take(19),
          CargoTransaction(
            commodityId: decision.commodityId,
            quantity: decision.quantity,
            pricePerUnit: decision.pricePerUnit,
            isBuy: true,
            turn: 0,
            reason: decision.reason,
          ),
        ],
      );
      return (newWarehouse: newWarehouse, newCrew: newCrew, cashDelta: -cost);
    } else if (decision.action == CrewAction.sell) {
      final revenue = decision.quantity * decision.pricePerUnit;
      final newWarehouse = List<Cargo>.from(warehouse);
      final idx = newWarehouse.indexWhere((c) => c.commodityId == decision.commodityId);
      if (idx < 0) {
        return (newWarehouse: warehouse, newCrew: crew, cashDelta: 0);
      }
      final cargo = newWarehouse[idx];
      if (cargo.quantity < decision.quantity) {
        return (newWarehouse: warehouse, newCrew: crew, cashDelta: 0);
      }
      if (cargo.quantity == decision.quantity) {
        newWarehouse.removeAt(idx);
      } else {
        newWarehouse[idx] = cargo.copyWith(quantity: cargo.quantity - decision.quantity);
      }
      final newCrew = crew.copyWith(
        funding: crew.funding + revenue,
        history: [
          ...crew.history.take(19),
          CargoTransaction(
            commodityId: decision.commodityId,
            quantity: decision.quantity,
            pricePerUnit: decision.pricePerUnit,
            isBuy: false,
            turn: 0,
            reason: decision.reason,
          ),
        ],
      );
      return (newWarehouse: newWarehouse, newCrew: newCrew, cashDelta: revenue);
    }
    return (newWarehouse: warehouse, newCrew: crew, cashDelta: 0);
  }

  /// Hire a new crew at a planet.
  Crew hireCrew({
    required String planetId,
    required String name,
    required int initialFunding,
    required int currentTurn,
    double skill = 0.5,
  }) {
    return Crew(
      id: 'crew_${planetId}_${DateTime.now().millisecondsSinceEpoch}',
      planetId: planetId,
      name: name,
      funding: initialFunding,
      skill: skill,
      hiredOnTurn: currentTurn,
      status: initialFunding > 0 ? CrewStatus.active : CrewStatus.idle,
    );
  }

  /// Withdraw all cargo and cash from a crew (player override).
  ({List<Cargo> cargo, int cash, Crew newCrew}) withdrawCrew({
    required Crew crew,
    required List<Cargo> warehouse,
  }) {
    final crewCargo = warehouse
        .where((c) => c.commodityId.startsWith('crew_${crew.id}_'))
        .toList();
    final newWarehouse = warehouse
        .where((c) => !c.commodityId.startsWith('crew_${crew.id}_'))
        .toList();
    final newCrew = crew.copyWith(funding: 0, status: CrewStatus.suspended);
    return (cargo: crewCargo, cash: crew.funding, newCrew: newCrew);
  }
}
