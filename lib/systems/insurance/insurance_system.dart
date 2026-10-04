import 'package:uuid/uuid.dart';
import '../../models/insurance.dart';
import '../../models/planet.dart';
import '../../config/game_config.dart';

class InsuranceResult {
  final bool success;
  final String message;
  final InsurancePolicy? policy;
  const InsuranceResult(this.success, this.message, {this.policy});
}

/// Per-planet insurance system.
class InsuranceSystem {
  final Uuid _uuid = const Uuid();

  /// Get the company name for a planet.
  static String getCompanyName(Planet planet) {
    if (planet.lawLevel == LawLevel.lawless) {
      return 'No insurance available';
    }
    if (planet.lawLevel == LawLevel.strict) {
      return '${planet.name} Reliable Insurance';
    }
    if (planet.governmentType == GovernmentType.plutocraticCouncil) {
      return 'Venus Luxury Assurance';
    }
    return '${planet.name} Insurance Co-op';
  }

  /// Calculate premium for a coverage tier based on fleet + cargo value.
  int calculatePremium({
    required InsuranceTier tier,
    required int fleetValue,
    required int cargoValue,
  }) {
    final base = (fleetValue + cargoValue) * _getRate(tier);
    // Lawless planets can't get insurance
    return base.round();
  }

  double _getRate(InsuranceTier tier) {
    switch (tier) {
      case InsuranceTier.basic: return GameConfig.insuranceBasicRate;
      case InsuranceTier.standard: return GameConfig.insuranceStandardRate;
      case InsuranceTier.premium: return GameConfig.insurancePremiumRate;
      case InsuranceTier.none: return 0;
    }
  }

  /// Buy an insurance policy.
  InsuranceResult buyPolicy({
    required Planet planet,
    required InsuranceTier tier,
    required int fleetValue,
    required int cargoValue,
    required int currentTurn,
  }) {
    if (planet.lawLevel == LawLevel.lawless) {
      return const InsuranceResult(false, 'Insurance not available on lawless worlds.');
    }
    if (tier == InsuranceTier.none) {
      return const InsuranceResult(false, 'Invalid coverage tier.');
    }

    final premium = calculatePremium(
      tier: tier,
      fleetValue: fleetValue,
      cargoValue: cargoValue,
    );

    final policy = InsurancePolicy(
      id: _uuid.v4(),
      planetId: planet.id,
      companyName: getCompanyName(planet),
      tier: tier,
      premiumPerTurn: premium,
      startTurn: currentTurn,
    );

    return InsuranceResult(
      true,
      'Policy purchased with ${getCompanyName(planet)}. Premium: $premium cr/turn.',
      policy: policy,
    );
  }

  /// Get cargo coverage for a tier.
  double getCargoCoverage(InsuranceTier tier) {
    switch (tier) {
      case InsuranceTier.basic: return 0.0;
      case InsuranceTier.standard: return GameConfig.insuranceStandardCargoCoverage;
      case InsuranceTier.premium: return GameConfig.insurancePremiumCargoCoverage;
      case InsuranceTier.none: return 0.0;
    }
  }

  /// Cancel a policy.
  void cancelPolicy(InsurancePolicy policy) {
    // No refund per spec
  }
}
