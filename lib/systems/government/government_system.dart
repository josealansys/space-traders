import 'dart:math';
import '../../models/mission.dart';
import '../../models/planet.dart';
import '../../models/commodity.dart';
import '../../config/game_config.dart';

/// Government mission system — generates and manages missions.
class GovernmentSystem {
  final Random _rng;

  GovernmentSystem({Random? rng}) : _rng = rng ?? Random();

  /// Generate available missions for a planet.
  ///
  /// Smart filtering: a planet only offers missions that match its
  /// specialties. A "Deliver Electronics to Neptune" mission will only
  /// appear on planets that actually produce or trade electronics.
  List<Mission> generateMissionsForPlanet({
    required Planet planet,
    required List<Commodity> commodities,
    required int currentTurn,
    int count = 3,
  }) {
    final missions = <Mission>[];

    // Mission templates — each template specifies which commodity types
    // make sense at the offering planet.
    final templates = _getMissionTemplates(planet);

    for (int i = 0; i < count && i < templates.length; i++) {
      final template = templates[i];
      final commodity = commodities.firstWhere(
        (c) => c.id == template.commodityId,
        orElse: () => commodities.first,
      );

      // Quantity scales with difficulty
      final quantity = _rng.nextInt(20) + 10 + (i * 5);
      final baseReward = GameConfig.missionMinReward +
          _rng.nextInt(GameConfig.missionMaxReward - GameConfig.missionMinReward);

      // Specialty planets get bonus rewards
      final specialtyBonus = planet.specialties.contains(commodity.id)
          ? (baseReward * 0.3).round()
          : 0;
      final reward = baseReward + specialtyBonus;
      final creditBoost = GameConfig.missionCreditBoost + (i * 25);

      missions.add(Mission(
        id: 'mission_${planet.id}_${commodity.id}_${currentTurn}_$i',
        planetId: planet.id,
        governorName: planet.governorName,
        description: template.description,
        commodityId: commodity.id,
        quantity: quantity,
        rewardCredits: reward,
        rewardCreditScore: creditBoost,
        acceptedOnTurn: currentTurn,
        deadlineTurn: currentTurn + GameConfig.missionDeadlineTurns,
        status: MissionStatus.available,
      ));
    }

    return missions;
  }

  /// Get mission templates that match this planet's economy.
  List<_MissionTemplate> _getMissionTemplates(Planet planet) {
    final all = <_MissionTemplate>[
      // Essential missions — every planet needs these
      _MissionTemplate(
        commodityId: 'food',
        description:
            'Our colony faces famine. Deliver Food supplies to sustain our people.',
      ),
      _MissionTemplate(
        commodityId: 'water',
        description:
            'Water recyclers are failing. We need clean Water urgently.',
      ),

      // Specialty missions — only on relevant planets
      if (planet.specialties.contains('electronics') ||
          planet.basePrices['electronics']! < 300)
        _MissionTemplate(
          commodityId: 'electronics',
          description:
              'Our research lab needs Electronics components for vital projects.',
        ),
      if (planet.specialties.contains('medicine') ||
          planet.basePrices['medicine']! < 300)
        _MissionTemplate(
          commodityId: 'medicine',
          description:
              'Medical crisis! Our hospitals need Medicine to treat the sick.',
        ),
      if (planet.specialties.contains('luxury') ||
          planet.basePrices['luxury']! < 500)
        _MissionTemplate(
          commodityId: 'luxury',
          description:
              'The Governor\'s banquet requires Luxury Goods for visiting dignitaries.',
        ),
      if (planet.specialties.contains('tech'))
        _MissionTemplate(
          commodityId: 'tech',
          description:
              'Our engineers need Tech Parts to complete critical repairs.',
        ),
      if (planet.specialties.contains('ore') ||
          planet.basePrices['ore']! < 50)
        _MissionTemplate(
          commodityId: 'ore',
          description:
              'Construction projects stalled. We need raw Ore to continue building.',
        ),
      if (planet.specialties.contains('fuel') ||
          planet.basePrices['fuel']! < 50)
        _MissionTemplate(
          commodityId: 'fuel',
          description:
              'Refineries are offline. We need Fuel to keep our fleet operational.',
        ),
    ];

    return all;
  }

  /// Check if a player can accept a mission (has the cargo or will get it).
  bool canAcceptMission({
    required Mission mission,
    required int availableCargoQuantity,
  }) {
    return availableCargoQuantity >= mission.quantity;
  }

  /// Complete a mission — returns reward info.
  ({int credits, int creditScore, String message}) completeMission(Mission mission) {
    return (
      credits: mission.rewardCredits,
      creditScore: mission.rewardCreditScore,
      message:
          'Mission complete! ${mission.governorName} pays ${mission.rewardCredits} cr.',
    );
  }

  /// Update mission statuses at end of turn.
  List<(String, MissionStatus)> updateMissionStatuses({
    required List<Mission> missions,
    required int currentTurn,
  }) {
    final updates = <(String, MissionStatus)>[];
    for (final m in missions) {
      if (m.status == MissionStatus.completed || m.status == MissionStatus.failed) continue;
      if (currentTurn > m.deadlineTurn && m.status == MissionStatus.active) {
        updates.add((m.id, MissionStatus.failed));
      }
    }
    return updates;
  }
}

class _MissionTemplate {
  final String commodityId;
  final String description;
  const _MissionTemplate({required this.commodityId, required this.description});
}
