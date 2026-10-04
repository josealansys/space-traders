import 'dart:math';
import '../../models/planet.dart';
import '../../config/game_config.dart';

enum EncounterType { pirate, police, trader, nothing }

class Encounter {
  final EncounterType type;
  final String enemyName;
  final int enemyWeapons;
  final int? enemyCargoValue; // for traders
  final String description;
  final List<EncounterOption> options;

  const Encounter({
    required this.type,
    required this.enemyName,
    required this.enemyWeapons,
    this.enemyCargoValue,
    required this.description,
    required this.options,
  });
}

class EncounterOption {
  final String label;
  final String description;
  final EncounterAction action;
  const EncounterOption({
    required this.label,
    required this.description,
    required this.action,
  });
}

enum EncounterAction { trade, attack, flee, pay, submit, decline }

class EncounterResult {
  final bool playerWon;
  final int creditsLost;
  final int creditsGained;
  final int cargoLost;
  final int weaponsLost;
  final int bountyGained;
  final int shipDamage;
  final String message;
  final bool policeFine;

  const EncounterResult({
    required this.playerWon,
    this.creditsLost = 0,
    this.creditsGained = 0,
    this.cargoLost = 0,
    this.weaponsLost = 0,
    this.bountyGained = 0,
    this.shipDamage = 0,
    required this.message,
    this.policeFine = false,
  });
}

/// Random encounter + combat system.
class CombatSystem {
  final Random _rng;

  CombatSystem({Random? rng}) : _rng = rng ?? Random();

  /// Roll for a random encounter.
  ///
  /// Returns null if no encounter.
  Encounter? rollEncounter({
    required Planet fromPlanet,
    required Planet toPlanet,
    required int playerWeapons,
  }) {
    if (_rng.nextDouble() > GameConfig.encounterChance) return null;

    final roll = _rng.nextDouble();
    EncounterType type;
    if (roll < GameConfig.pirateEncounterRatio) {
      type = EncounterType.pirate;
    } else if (roll < GameConfig.pirateEncounterRatio + GameConfig.policeEncounterRatio) {
      type = EncounterType.police;
    } else if (roll < 1.0) {
      type = EncounterType.trader;
    } else {
      type = EncounterType.nothing;
    }

    return _generateEncounter(type: type, fromPlanet: fromPlanet, toPlanet: toPlanet, playerWeapons: playerWeapons);
  }

  Encounter _generateEncounter({
    required EncounterType type,
    required Planet fromPlanet,
    required Planet toPlanet,
    required int playerWeapons,
  }) {
    switch (type) {
      case EncounterType.pirate:
        final enemyWeapons = _rng.nextInt(playerWeapons + 2).clamp(1, 10);
        return Encounter(
          type: type,
          enemyName: _pirateNames[_rng.nextInt(_pirateNames.length)],
          enemyWeapons: enemyWeapons,
          description:
              'A pirate ship decloaks ahead! ${enemyWeapons >= playerWeapons ? "They look stronger than you." : "You might have the upper hand."}',
          options: [
            const EncounterOption(
              label: 'FIGHT',
              description: 'Engage in combat',
              action: EncounterAction.attack,
            ),
            const EncounterOption(
              label: 'FLEE',
              description: 'Attempt to escape',
              action: EncounterAction.flee,
            ),
            const EncounterOption(
              label: 'PAY TOLL',
              description: 'Pay 200cr to pass safely',
              action: EncounterAction.pay,
            ),
          ],
        );

      case EncounterType.police:
        // Police strength depends on destination planet's law level
        final enemyWeapons = toPlanet.lawLevel == LawLevel.strict ? 5 : 3;
        return Encounter(
          type: type,
          enemyName: '${toPlanet.name} Patrol',
          enemyWeapons: enemyWeapons,
          description:
              'Patrol vessel from ${toPlanet.name} hails you. ${toPlanet.lawLevel == LawLevel.strict ? "Strict inspection incoming." : "Routine scan."}',
          options: [
            const EncounterOption(
              label: 'SUBMIT TO SCAN',
              description: 'Allow inspection',
              action: EncounterAction.submit,
            ),
            const EncounterOption(
              label: 'FLEE',
              description: 'Attempt to escape (raises bounty)',
              action: EncounterAction.flee,
            ),
            const EncounterOption(
              label: 'ATTACK',
              description: 'Attack the patrol (big bounty)',
              action: EncounterAction.attack,
            ),
          ],
        );

      case EncounterType.trader:
        final enemyWeapons = _rng.nextInt(3) + 1;
        final cargoValue = (_rng.nextInt(5) + 1) * 500;
        return Encounter(
          type: type,
          enemyName: _traderNames[_rng.nextInt(_traderNames.length)],
          enemyWeapons: enemyWeapons,
          enemyCargoValue: cargoValue,
          description:
              'A friendly trader ship approaches, offering to trade goods worth ~$cargoValue cr.',
          options: [
            const EncounterOption(
              label: 'TRADE',
              description: 'Negotiate a deal',
              action: EncounterAction.trade,
            ),
            const EncounterOption(
              label: 'ATTACK',
              description: 'Attack and steal their cargo (big bounty)',
              action: EncounterAction.attack,
            ),
            const EncounterOption(
              label: 'IGNORE',
              description: 'Wave them off',
              action: EncounterAction.decline,
            ),
          ],
        );

      case EncounterType.nothing:
        return Encounter(
          type: type,
          enemyName: '',
          enemyWeapons: 0,
          description: 'The route is clear. Safe travels.',
          options: const [
            EncounterOption(
              label: 'CONTINUE',
              description: 'Continue journey',
              action: EncounterAction.decline,
            ),
          ],
        );
    }
  }

  /// Resolve a combat action.
  EncounterResult resolveCombat({
    required Encounter encounter,
    required EncounterAction action,
    required int playerWeapons,
    required int playerCredits,
    required int currentBounty,
  }) {
    switch (action) {
      case EncounterAction.attack:
        return _resolveAttack(
          encounter: encounter,
          playerWeapons: playerWeapons,
          playerCredits: playerCredits,
          currentBounty: currentBounty,
        );

      case EncounterAction.flee:
        if (_rng.nextDouble() < 0.6) {
          return EncounterResult(
            playerWon: true,
            message: 'You escaped successfully!',
          );
        } else {
          return EncounterResult(
            playerWon: false,
            shipDamage: 20,
            cargoLost: 1,
            bountyGained: encounter.type == EncounterType.police ? 30 : 0,
            message: 'Escape failed! You took damage${encounter.type == EncounterType.police ? " and gained a bounty" : ""}.',
          );
        }

      case EncounterAction.pay:
        if (playerCredits < 200) {
          return EncounterResult(
            playerWon: false,
            creditsLost: playerCredits,
            cargoLost: 1,
            message: 'Not enough to pay. They took what they could.',
          );
        }
        return EncounterResult(
          playerWon: true,
          creditsLost: 200,
          message: 'Toll paid. The pirates let you pass.',
        );

      case EncounterAction.submit:
        // Police scan: small chance of contraband bust
        final contrabandBust = _rng.nextDouble() < 0.3;
        if (contrabandBust) {
          return EncounterResult(
            playerWon: false,
            creditsLost: 1000,
            bountyGained: 50,
            policeFine: true,
            message: 'Contraband found! Fined 1000cr and gained 50 bounty.',
          );
        }
        return const EncounterResult(
          playerWon: true,
          message: 'Scan complete. Nothing flagged. Safe to proceed.',
        );

      case EncounterAction.trade:
        return EncounterResult(
          playerWon: true,
          creditsLost: encounter.enemyCargoValue!,
          message: 'Traded for cargo worth ${encounter.enemyCargoValue} cr.',
        );

      case EncounterAction.decline:
        return EncounterResult(
          playerWon: true,
          message: 'You continue on your way.',
        );
    }
  }

  EncounterResult _resolveAttack({
    required Encounter encounter,
    required int playerWeapons,
    required int playerCredits,
    required int currentBounty,
  }) {
    final isTrader = encounter.type == EncounterType.trader;
    final isPolice = encounter.type == EncounterType.police;

    if (playerWeapons > encounter.enemyWeapons) {
      // Win
      if (isTrader) {
        return EncounterResult(
          playerWon: true,
          creditsGained: encounter.enemyCargoValue ?? 0,
          bountyGained: GameConfig.bountyPerAttack,
          message:
              'Victory! You seized cargo worth ${encounter.enemyCargoValue} cr. +${GameConfig.bountyPerAttack} bounty.',
        );
      } else if (isPolice) {
        return EncounterResult(
          playerWon: true,
          creditsGained: 500,
          bountyGained: GameConfig.bountyPerAttack * 3,
          message:
              'You destroyed a patrol! +500 cr but +${GameConfig.bountyPerAttack * 3} bounty.',
        );
      } else {
        return EncounterResult(
          playerWon: true,
          creditsGained: 300,
          message: 'Pirate destroyed! Looted 300 cr.',
        );
      }
    } else if (playerWeapons < encounter.enemyWeapons) {
      // Lose
      final creditsToTake = (playerCredits * 0.2).round();
      return EncounterResult(
        playerWon: false,
        creditsLost: creditsToTake,
        cargoLost: 3,
        weaponsLost: 1,
        shipDamage: 30,
        message: 'Defeated! Lost ${creditsToTake}cr, cargo, and a weapon. Ship damaged.',
      );
    } else {
      // Draw
      return EncounterResult(
        playerWon: false,
        shipDamage: 15,
        message: 'Stalemate. Both ships damaged. You escaped with critical damage.',
      );
    }
  }

  static const _pirateNames = [
    'Black Nebula',
    'Crimson Void',
    'Iron Talon',
    'Star Reaver',
    'Shadow Fang',
  ];

  static const _traderNames = [
    'Wandering Merchant',
    'Free Trader',
    'Independent Hauler',
    'Lucky Star',
    'Compass Rose',
  ];
}
