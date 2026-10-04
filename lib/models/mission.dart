/// Status of a mission.
enum MissionStatus {
  available, // can be accepted
  active,    // accepted, in progress
  completed, // succeeded
  failed,    // deadline passed
  expired,   // offer expired
}

/// A mission from a planet's governor.
class Mission {
  final String id;
  final String planetId; // where mission is offered
  final String governorName;
  final String description;
  final String commodityId; // required cargo
  final int quantity; // required amount
  final int rewardCredits;
  final int rewardCreditScore;
  final int acceptedOnTurn;
  final int deadlineTurn; // must complete by this turn
  final MissionStatus status;

  const Mission({
    required this.id,
    required this.planetId,
    required this.governorName,
    required this.description,
    required this.commodityId,
    required this.quantity,
    required this.rewardCredits,
    required this.rewardCreditScore,
    required this.acceptedOnTurn,
    required this.deadlineTurn,
    this.status = MissionStatus.active,
  });

  int turnsUntilDeadline(int currentTurn) {
    return deadlineTurn - currentTurn;
  }

  bool isExpired(int currentTurn) {
    return currentTurn > deadlineTurn && status == MissionStatus.active;
  }

  Mission copyWith({
    String? id,
    String? planetId,
    String? governorName,
    String? description,
    String? commodityId,
    int? quantity,
    int? rewardCredits,
    int? rewardCreditScore,
    int? acceptedOnTurn,
    int? deadlineTurn,
    MissionStatus? status,
  }) {
    return Mission(
      id: id ?? this.id,
      planetId: planetId ?? this.planetId,
      governorName: governorName ?? this.governorName,
      description: description ?? this.description,
      commodityId: commodityId ?? this.commodityId,
      quantity: quantity ?? this.quantity,
      rewardCredits: rewardCredits ?? this.rewardCredits,
      rewardCreditScore: rewardCreditScore ?? this.rewardCreditScore,
      acceptedOnTurn: acceptedOnTurn ?? this.acceptedOnTurn,
      deadlineTurn: deadlineTurn ?? this.deadlineTurn,
      status: status ?? this.status,
    );
  }
}
