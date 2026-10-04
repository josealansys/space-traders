import 'cargo.dart';
import 'crew.dart';
import 'insurance.dart';
import 'loan.dart';
import 'mission.dart';
import 'ship.dart';
import 'alert.dart';

/// Full game state — single source of truth.
class GameState {
  final int turn;
  final int credits;
  final int creditScore;
  final int bounty; // heat from attacking traders (0-1000)
  final String currentPlanetId;
  final List<Ship> ships; // all owned ships
  final String? activeShipId; // currently flying
  final Map<String, List<Cargo>> shipCargo; // shipId -> cargo
  final Map<String, List<Cargo>> warehouseCargo; // planetId -> cargo
  final List<Loan> loans;
  final List<Mission> missions; // active and available
  final List<Crew> crews;
  final List<InsurancePolicy> insurancePolicies;
  final Map<String, double> priceModifiers; // "planetId:commodityId" -> modifier
  final Map<String, int> priceLastRollTurn; // "planetId:commodityId" -> turn
  final List<Alert> alerts;
  final int saveVersion;
  final String saveName;
  final DateTime lastSaved;

  const GameState({
    this.turn = 0,
    this.credits = 5000,
    this.creditScore = 1000,
    this.bounty = 0,
    this.currentPlanetId = 'terra',
    this.ships = const [],
    this.activeShipId,
    this.shipCargo = const {},
    this.warehouseCargo = const {},
    this.loans = const [],
    this.missions = const [],
    this.crews = const [],
    this.insurancePolicies = const [],
    this.priceModifiers = const {},
    this.priceLastRollTurn = const {},
    this.alerts = const [],
    this.saveVersion = 1,
    this.saveName = 'New Game',
    required this.lastSaved,
  });

  // Computed helpers
  Ship? get activeShip {
    if (activeShipId == null) return null;
    try {
      return ships.firstWhere((s) => s.id == activeShipId);
    } catch (_) {
      return null;
    }
  }

  List<Ship> get equippedShips => ships.where((s) => s.equipped).toList();
  List<Ship> get storedShips => ships.where((s) => !s.equipped).toList();
  List<Ship> get flyingShips =>
      ships.where((s) => s.equipped && s.currentPlanetId == null).toList();

  int get totalDebt {
    return loans
        .where((l) => l.status != LoanStatus.repaid && l.status != LoanStatus.defaulted)
        .fold(0, (sum, loan) => sum + loan.getCurrentDebt(turn));
  }

  /// Create a fresh game state.
  factory GameState.fresh() {
    return GameState(lastSaved: DateTime.now());
  }

  GameState copyWith({
    int? turn,
    int? credits,
    int? creditScore,
    int? bounty,
    String? currentPlanetId,
    List<Ship>? ships,
    String? activeShipId,
    Map<String, List<Cargo>>? shipCargo,
    Map<String, List<Cargo>>? warehouseCargo,
    List<Loan>? loans,
    List<Mission>? missions,
    List<Crew>? crews,
    List<InsurancePolicy>? insurancePolicies,
    Map<String, double>? priceModifiers,
    Map<String, int>? priceLastRollTurn,
    List<Alert>? alerts,
    int? saveVersion,
    String? saveName,
    DateTime? lastSaved,
  }) {
    return GameState(
      turn: turn ?? this.turn,
      credits: credits ?? this.credits,
      creditScore: creditScore ?? this.creditScore,
      bounty: bounty ?? this.bounty,
      currentPlanetId: currentPlanetId ?? this.currentPlanetId,
      ships: ships ?? this.ships,
      activeShipId: activeShipId ?? this.activeShipId,
      shipCargo: shipCargo ?? this.shipCargo,
      warehouseCargo: warehouseCargo ?? this.warehouseCargo,
      loans: loans ?? this.loans,
      missions: missions ?? this.missions,
      crews: crews ?? this.crews,
      insurancePolicies: insurancePolicies ?? this.insurancePolicies,
      priceModifiers: priceModifiers ?? this.priceModifiers,
      priceLastRollTurn: priceLastRollTurn ?? this.priceLastRollTurn,
      alerts: alerts ?? this.alerts,
      saveVersion: saveVersion ?? this.saveVersion,
      saveName: saveName ?? this.saveName,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }
}
