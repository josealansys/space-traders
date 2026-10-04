/// Insurance coverage tier.
enum InsuranceTier {
  none,
  basic,     // ship repair only
  standard,  // ship + 50% cargo
  premium,   // ship + 100% cargo + medical
}

/// An insurance policy at a planet.
class InsurancePolicy {
  final String id;
  final String planetId; // insurance company
  final String companyName;
  final InsuranceTier tier;
  final int premiumPerTurn; // cost per turn
  final int startTurn;
  final bool active;

  const InsurancePolicy({
    required this.id,
    required this.planetId,
    required this.companyName,
    required this.tier,
    required this.premiumPerTurn,
    required this.startTurn,
    this.active = true,
  });

  InsurancePolicy copyWith({
    String? id,
    String? planetId,
    String? companyName,
    InsuranceTier? tier,
    int? premiumPerTurn,
    int? startTurn,
    bool? active,
  }) {
    return InsurancePolicy(
      id: id ?? this.id,
      planetId: planetId ?? this.planetId,
      companyName: companyName ?? this.companyName,
      tier: tier ?? this.tier,
      premiumPerTurn: premiumPerTurn ?? this.premiumPerTurn,
      startTurn: startTurn ?? this.startTurn,
      active: active ?? this.active,
    );
  }
}
