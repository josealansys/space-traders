import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/planet.dart';
import '../models/commodity.dart';
import '../models/ship.dart';
import '../models/cargo.dart';
import '../models/loan.dart';
import '../models/mission.dart';
import '../models/crew.dart';
import '../models/insurance.dart';
import '../models/alert.dart';
import '../models/game_state.dart';
import '../data/data_loader.dart';
import '../config/game_config.dart';
import '../systems/trading/trading_system.dart';
import '../systems/banking/banking_system.dart';
import '../systems/government/government_system.dart';
import '../systems/warehouse/crew_engine.dart';
import '../systems/combat/combat_system.dart';
import '../systems/fleet/fleet_system.dart';
import '../systems/insurance/insurance_system.dart';
import '../systems/alerts/alert_system.dart';
import '../core/save_system.dart';

// === Data providers ===
final commoditiesProvider = FutureProvider<List<Commodity>>((ref) async {
  final data = await DataLoader.loadCommodities();
  return data.map((j) => Commodity.fromJson(j)).toList();
});

final planetsProvider = FutureProvider<List<Planet>>((ref) async {
  final data = await DataLoader.loadPlanets();
  return data.map((j) => Planet.fromJson(j)).toList();
});

// === System providers ===
final tradingSystemProvider = Provider<TradingSystem>((ref) => TradingSystem());
final bankingSystemProvider = Provider<BankingSystem>((ref) => BankingSystem());
final governmentSystemProvider = Provider<GovernmentSystem>((ref) => GovernmentSystem());
final crewEngineProvider = Provider<CrewEngine>((ref) => CrewEngine(
      trading: ref.watch(tradingSystemProvider),
    ));
final combatSystemProvider = Provider<CombatSystem>((ref) => CombatSystem());
final fleetSystemProvider = Provider<FleetSystem>((ref) => FleetSystem());
final insuranceSystemProvider = Provider<InsuranceSystem>((ref) => InsuranceSystem());
final alertSystemProvider = Provider<AlertSystem>((ref) => AlertSystem());
final saveSystemProvider = Provider<SaveSystem>((ref) => SaveSystem());

// === Game state ===
class GameStateNotifier extends Notifier<GameState> {
  final Uuid _uuid = const Uuid();

  @override
  GameState build() => GameState.fresh();

  /// Start a fresh game — player must buy their first ship.
  void startNewGame() {
    state = state.copyWith(
      turn: 0,
      credits: GameConfig.startingCredits,
      creditScore: GameConfig.startingCreditScore,
      bounty: 0,
      currentPlanetId: 'terra',
      ships: [],
      activeShipId: null,
      shipCargo: {},
      warehouseCargo: {},
      loans: [],
      missions: [],
      crews: [],
      insurancePolicies: [],
      priceModifiers: {},
      priceLastRollTurn: {},
      saveName: 'New Game',
      lastSaved: DateTime.now(),
    );
  }

  // === TRAVEL + TRADE ===
  void travelTo(String planetId) {
    if (planetId == state.currentPlanetId) return;
    final planet = ref.read(planetsProvider).asData?.value
        ?.firstWhere((p) => p.id == planetId, orElse: () => throw 'Planet not found');
    if (planet == null) return;
    if (state.credits < planet.travelCost) return;
    state = state.copyWith(
      credits: state.credits - planet.travelCost,
      currentPlanetId: planetId,
      turn: state.turn + 1,
      lastSaved: DateTime.now(),
    );
  }

  void buyCargo(String commodityId, int quantity, int pricePerUnit) {
    final cost = quantity * pricePerUnit;
    if (state.credits < cost || state.activeShipId == null) return;
    final shipId = state.activeShipId!;
    final ship = state.ships.firstWhere((s) => s.id == shipId);
    final currentCargo = state.shipCargo[shipId] ?? [];
    final used = currentCargo.fold<int>(0, (s, c) => s + c.quantity);
    if (quantity > ship.cargoCapacity - used) return;
    final newCargo = List<Cargo>.from(currentCargo);
    final idx = newCargo.indexWhere((c) => c.commodityId == commodityId);
    if (idx >= 0) {
      newCargo[idx] = newCargo[idx].copyWith(quantity: newCargo[idx].quantity + quantity);
    } else {
      newCargo.add(Cargo(commodityId: commodityId, quantity: quantity));
    }
    state = state.copyWith(
      credits: state.credits - cost,
      shipCargo: {...state.shipCargo, shipId: newCargo},
      lastSaved: DateTime.now(),
    );
  }

  void sellCargo(String commodityId, int quantity, int pricePerUnit) {
    final shipId = state.activeShipId;
    if (shipId == null) return;
    final currentCargo = state.shipCargo[shipId] ?? [];
    final idx = currentCargo.indexWhere((c) => c.commodityId == commodityId);
    if (idx < 0) return;
    final cargo = currentCargo[idx];
    if (cargo.quantity < quantity) return;
    final newCargo = List<Cargo>.from(currentCargo);
    if (cargo.quantity == quantity) {
      newCargo.removeAt(idx);
    } else {
      newCargo[idx] = cargo.copyWith(quantity: cargo.quantity - quantity);
    }
    state = state.copyWith(
      credits: state.credits + quantity * pricePerUnit,
      shipCargo: {...state.shipCargo, shipId: newCargo},
      lastSaved: DateTime.now(),
    );
  }

  // === BANKING ===
  bool takeLoan(String planetId, int amount) {
    final planet = ref.read(planetsProvider).asData?.value
        ?.firstWhere((p) => p.id == planetId);
    if (planet == null) return false;
    final banking = ref.read(bankingSystemProvider);
    final result = banking.takeLoan(
      planet: planet,
      amount: amount,
      currentTurn: state.turn,
      creditScore: state.creditScore,
    );
    if (!result.success || result.loan == null) return false;
    state = state.copyWith(
      credits: state.credits + amount,
      loans: [...state.loans, result.loan!],
      lastSaved: DateTime.now(),
    );
    return true;
  }

  bool repayLoan(String loanId, int amount) {
    final loan = state.loans.firstWhere((l) => l.id == loanId, orElse: () => state.loans.first);
    if (loan.id != loanId) return false;
    final banking = ref.read(bankingSystemProvider);
    final result = banking.repayLoan(loan: loan, amount: amount, availableCredits: state.credits);
    if (!result.success) return false;
    state = state.copyWith(
      credits: state.credits - result.amountPaid,
      loans: state.loans.map((l) => l.id == loanId ? result.newLoan! : l).toList(),
      creditScore: result.newLoan?.status == LoanStatus.repaid
          ? state.creditScore + GameConfig.creditOnTimeRepay
          : state.creditScore,
      lastSaved: DateTime.now(),
    );
    return true;
  }

  // === MISSIONS ===
  void generateMissionsForCurrentPlanet() {
    final planet = ref.read(planetsProvider).asData?.value
        ?.firstWhere((p) => p.id == state.currentPlanetId);
    if (planet == null) return;
    final commodities = ref.read(commoditiesProvider).asData?.value ?? [];
    final gov = ref.read(governmentSystemProvider);
    final missions = gov.generateMissionsForPlanet(
      planet: planet,
      commodities: commodities,
      currentTurn: state.turn,
    );
    // Filter out missions that already exist
    final existingIds = state.missions.map((m) => m.id).toSet();
    final newMissions = missions.where((m) => !existingIds.contains(m.id)).toList();
    if (newMissions.isNotEmpty) {
      state = state.copyWith(missions: [...state.missions, ...newMissions]);
    }
  }

  bool acceptMission(String missionId) {
    final mission = state.missions.firstWhere((m) => m.id == missionId, orElse: () => state.missions.first);
    if (mission.id != missionId || mission.status != MissionStatus.available) return false;
    final updated = mission.copyWith(status: MissionStatus.active);
    state = state.copyWith(
      missions: state.missions.map((m) => m.id == missionId ? updated : m).toList(),
    );
    return true;
  }

  // === AI CREWS ===
  Crew hireCrew(String planetId, String name, int initialFunding) {
    final crew = ref.read(crewEngineProvider).hireCrew(
          planetId: planetId,
          name: name,
          initialFunding: initialFunding,
          currentTurn: state.turn,
        );
    state = state.copyWith(
      crews: [...state.crews, crew],
      credits: state.credits - initialFunding,
      lastSaved: DateTime.now(),
    );
    return crew;
  }

  void fundCrew(String crewId, int amount) {
    if (state.credits < amount) return;
    final updated = state.crews.map((c) {
      if (c.id == crewId) {
        return c.copyWith(
          funding: c.funding + amount,
          status: c.funding + amount > 0 ? CrewStatus.active : CrewStatus.idle,
        );
      }
      return c;
    }).toList();
    state = state.copyWith(
      crews: updated,
      credits: state.credits - amount,
      lastSaved: DateTime.now(),
    );
  }

  // === FLEET ===
  void buyShip(Ship newShip) {
    if (state.credits < newShip.price) return;
    if (state.ships.length >= GameConfig.maxShipsOwned) return;
    state = state.copyWith(
      ships: [...state.ships, newShip],
      credits: state.credits - newShip.price,
      lastSaved: DateTime.now(),
    );
  }

  void upgradeShipCargo(String shipId) {
    final fleet = ref.read(fleetSystemProvider);
    final ship = state.ships.firstWhere((s) => s.id == shipId);
    final result = fleet.upgradeCargo(ship: ship);
    if (!result.success) return;
    if (state.credits < ship.cargoUpgradeCost) return;
    final updated = ship.copyWith(cargoUpgrades: ship.cargoUpgrades + 1);
    state = state.copyWith(
      ships: state.ships.map((s) => s.id == shipId ? updated : s).toList(),
      credits: state.credits - ship.cargoUpgradeCost,
      lastSaved: DateTime.now(),
    );
  }

  void upgradeShipWeapons(String shipId) {
    final fleet = ref.read(fleetSystemProvider);
    final ship = state.ships.firstWhere((s) => s.id == shipId);
    final result = fleet.upgradeWeapons(ship: ship);
    if (!result.success) return;
    if (state.credits < ship.weaponUpgradeCost) return;
    final updated = ship.copyWith(weaponUpgrades: ship.weaponUpgrades + 1);
    state = state.copyWith(
      ships: state.ships.map((s) => s.id == shipId ? updated : s).toList(),
      credits: state.credits - ship.weaponUpgradeCost,
      lastSaved: DateTime.now(),
    );
  }

  void repairShip(String shipId) {
    final ship = state.ships.firstWhere((s) => s.id == shipId);
    if (ship.damage == 0) return;
    if (state.credits < ship.repairCost) return;
    final updated = ship.copyWith(damage: 0);
    state = state.copyWith(
      ships: state.ships.map((s) => s.id == shipId ? updated : s).toList(),
      credits: state.credits - ship.repairCost,
      lastSaved: DateTime.now(),
    );
  }

  void equipShip(String shipId) {
    final ship = state.ships.firstWhere((s) => s.id == shipId);
    if (ship.equipped) return;
    final equippedCount = state.equippedShips.length;
    if (equippedCount >= GameConfig.maxShipsEquipped) return;
    if (ship.isDamaged) return;
    final updated = ship.copyWith(equipped: true);
    state = state.copyWith(
      ships: state.ships.map((s) => s.id == shipId ? updated : s).toList(),
    );
  }

  void unequipShip(String shipId) {
    final ship = state.ships.firstWhere((s) => s.id == shipId);
    if (!ship.equipped) return;
    if (state.activeShipId == shipId) return; // can't unequip active
    final updated = ship.copyWith(equipped: false, currentPlanetId: state.currentPlanetId);
    state = state.copyWith(
      ships: state.ships.map((s) => s.id == shipId ? updated : s).toList(),
    );
  }

  void setActiveShip(String shipId) {
    if (state.activeShipId == shipId) return;
    final ship = state.ships.firstWhere((s) => s.id == shipId);
    if (!ship.equipped || ship.isDamaged) return;
    state = state.copyWith(activeShipId: shipId);
  }

  void sellShip(String shipId) {
    final ship = state.ships.firstWhere((s) => s.id == shipId);
    state = state.copyWith(
      ships: state.ships.where((s) => s.id != shipId).toList(),
      credits: state.credits + ship.sellValue,
      activeShipId: state.activeShipId == shipId ? null : state.activeShipId,
      lastSaved: DateTime.now(),
    );
  }

  // === INSURANCE ===
  bool buyInsurance(InsurancePolicy policy) {
    // Premium paid per turn, no upfront cost in this simplified model
    state = state.copyWith(
      insurancePolicies: [...state.insurancePolicies, policy],
    );
    return true;
  }

  void cancelInsurance(String policyId) {
    state = state.copyWith(
      insurancePolicies: state.insurancePolicies.where((p) => p.id != policyId).toList(),
    );
  }

  // === ALERTS ===
  void refreshAlerts() {
    final alertSys = ref.read(alertSystemProvider);
    final newAlerts = alertSys.generateAlerts(
      currentTurn: state.turn,
      loans: state.loans,
      missions: state.missions,
    );
    // Keep only undismissed, replace with new
    state = state.copyWith(alerts: newAlerts);
  }
}

final gameStateProvider = NotifierProvider<GameStateNotifier, GameState>(GameStateNotifier.new);
