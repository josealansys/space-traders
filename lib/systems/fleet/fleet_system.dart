import 'package:uuid/uuid.dart';
import '../../models/ship.dart';
import '../../models/planet.dart';
import '../../config/game_config.dart';

class FleetResult {
  final bool success;
  final String message;
  final Ship? ship;
  const FleetResult(this.success, this.message, {this.ship});
}

/// Fleet management system — buy, sell, upgrade, equip ships.
class FleetSystem {
  final Uuid _uuid = const Uuid();

  /// Buy a new ship at a planet.
  Ship buyShip({
    required String typeId,
    required String name,
    required int baseCargo,
    required int cargoUpgradeBonus,
    required int baseWeapons,
    required int price,
    required int cargoUpgradeCost,
    required int weaponUpgradeCost,
    required double speed,
    required String sprite,
  }) {
    return Ship(
      id: _uuid.v4(),
      typeId: typeId,
      name: name,
      baseCargo: baseCargo,
      cargoUpgradeBonus: cargoUpgradeBonus,
      baseWeapons: baseWeapons,
      weaponUpgradeBonus: 0,
      price: price,
      cargoUpgradeCost: cargoUpgradeCost,
      weaponUpgradeCost: weaponUpgradeCost,
      speed: speed,
      sprite: sprite,
      equipped: true,
    );
  }

  /// Upgrade cargo capacity.
  FleetResult upgradeCargo({required Ship ship}) {
    if (ship.cargoUpgrades >= 5) {
      return const FleetResult(false, 'Maximum cargo upgrades reached.');
    }
    final cost = ship.cargoUpgradeCost;
    return FleetResult(
      true,
      'Cargo upgrade purchased for $cost cr. New capacity: ${ship.cargoCapacity + GameConfig.cargoUpgradePerLevel}.',
    );
  }

  /// Upgrade weapons.
  FleetResult upgradeWeapons({required Ship ship}) {
    if (ship.weaponUpgrades >= 5) {
      return const FleetResult(false, 'Maximum weapon upgrades reached.');
    }
    final cost = ship.weaponUpgradeCost;
    return FleetResult(
      true,
      'Weapon upgrade purchased for $cost cr. New weapons: ${ship.totalWeapons + GameConfig.weaponUpgradePerLevel}.',
    );
  }

  /// Apply damage to a ship.
  Ship damageShip({required Ship ship, required int damageAmount}) {
    final newDamage = (ship.damage + damageAmount).clamp(0, 100);
    return ship.copyWith(damage: newDamage);
  }

  /// Repair a ship.
  FleetResult repairShip({required Ship ship}) {
    if (ship.damage == 0) {
      return const FleetResult(false, 'Ship is not damaged.');
    }
    return FleetResult(
      true,
      'Repair cost: ${ship.repairCost} cr. Ship fully restored.',
    );
  }

  /// Equip a ship (move from stored to active fleet).
  FleetResult equipShip({required Ship ship, required int equippedCount}) {
    if (ship.equipped) {
      return const FleetResult(false, 'Ship is already equipped.');
    }
    if (equippedCount >= GameConfig.maxShipsEquipped) {
      return FleetResult(
        false,
        'Cannot equip more than ${GameConfig.maxShipsEquipped} ships.',
      );
    }
    return FleetResult(true, '${ship.name} equipped.');
  }

  /// Unequip a ship (move from active to stored).
  FleetResult unequipShip({required Ship ship, required String currentPlanetId}) {
    if (!ship.equipped) {
      return const FleetResult(false, 'Ship is already stored.');
    }
    if (ship.currentPlanetId == null) {
      return FleetResult(
        false,
        'Cannot unequip a ship currently in flight. Land first.',
      );
    }
    return FleetResult(true, '${ship.name} stored.');
  }

  /// Sell a ship (returns sell value).
  FleetResult sellShip({required Ship ship}) {
    return FleetResult(
      true,
      '${ship.name} sold for ${ship.sellValue} cr.',
    );
  }

  /// Can this ship be equipped (meets all conditions)?
  bool canEquip(Ship ship, int currentEquippedCount) {
    if (ship.equipped) return false;
    if (currentEquippedCount >= GameConfig.maxShipsEquipped) return false;
    if (ship.isDamaged) return false; // damaged ships must be repaired first
    return true;
  }
}
