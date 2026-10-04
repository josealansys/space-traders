/// Status of an AI warehouse crew.
enum CrewStatus {
  idle,        // hired but no funds
  active,      // actively trading
  suspended,   // manually stopped
}

/// An AI crew that autonomously trades on a planet's warehouse.
class Crew {
  final String id;
  final String planetId;
  final String name;
  final int funding; // credits available for trading
  final double skill; // 0.0-1.0, affects decision quality
  final List<CargoTransaction> history; // recent activity
  final CrewStatus status;
  final int hiredOnTurn;

  const Crew({
    required this.id,
    required this.planetId,
    required this.name,
    this.funding = 0,
    this.skill = 0.5,
    this.history = const [],
    this.status = CrewStatus.idle,
    required this.hiredOnTurn,
  });

  Crew copyWith({
    String? id,
    String? planetId,
    String? name,
    int? funding,
    double? skill,
    List<CargoTransaction>? history,
    CrewStatus? status,
    int? hiredOnTurn,
  }) {
    return Crew(
      id: id ?? this.id,
      planetId: planetId ?? this.planetId,
      name: name ?? this.name,
      funding: funding ?? this.funding,
      skill: skill ?? this.skill,
      history: history ?? this.history,
      status: status ?? this.status,
      hiredOnTurn: hiredOnTurn ?? this.hiredOnTurn,
    );
  }
}

/// A single transaction by an AI crew.
class CargoTransaction {
  final String commodityId;
  final int quantity;
  final int pricePerUnit;
  final bool isBuy; // true = buy, false = sell
  final int turn;
  final String reason; // "Surplus detected", "Premium reached", etc.

  const CargoTransaction({
    required this.commodityId,
    required this.quantity,
    required this.pricePerUnit,
    required this.isBuy,
    required this.turn,
    required this.reason,
  });
}
