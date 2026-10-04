import 'package:flutter/material.dart';

/// A ship in the player's fleet.
class Ship {
  final String id; // unique instance id
  final String typeId; // scout, freighter, cruiser, dreadnought
  final String name;
  final int baseCargo;
  final int cargoUpgradeBonus;
  final int baseWeapons;
  final int weaponUpgradeBonus;
  final int price; // original purchase price
  final int cargoUpgradeCost;
  final int weaponUpgradeCost;
  final double speed;
  final String sprite;
  final int cargoUpgrades; // # of cargo upgrades purchased
  final int weaponUpgrades; // # of weapon upgrades purchased
  final int damage; // 0 = no damage, 100 = destroyed
  final String? currentPlanetId; // where the ship is parked, null = with player
  final bool equipped; // in active fleet (max 10)

  const Ship({
    required this.id,
    required this.typeId,
    required this.name,
    required this.baseCargo,
    required this.cargoUpgradeBonus,
    required this.baseWeapons,
    required this.weaponUpgradeBonus,
    required this.price,
    required this.cargoUpgradeCost,
    required this.weaponUpgradeCost,
    required this.speed,
    required this.sprite,
    this.cargoUpgrades = 0,
    this.weaponUpgrades = 0,
    this.damage = 0,
    this.currentPlanetId,
    this.equipped = false,
  });

  /// Total cargo capacity (base + bonuses + upgrades).
  int get cargoCapacity {
    return baseCargo +
        cargoUpgradeBonus +
        (cargoUpgrades * 5);
  }

  /// Total weapons (base + upgrades).
  int get totalWeapons {
    return baseWeapons + (weaponUpgrades * 1);
  }

  /// Total amount invested in this ship (price + upgrades).
  int get totalInvested {
    return price + (cargoUpgrades * cargoUpgradeCost) + (weaponUpgrades * weaponUpgradeCost);
  }

  /// Sell value (80% of invested).
  int get sellValue {
    return (totalInvested * 0.8).round();
  }

  /// Repair cost (10% of price).
  int get repairCost {
    return (price * 0.10).round();
  }

  /// Is this ship damaged?
  bool get isDamaged => damage > 0;

  /// Can this ship travel?
  bool get canTravel => !isDamaged;

  Ship copyWith({
    String? id,
    String? typeId,
    String? name,
    int? baseCargo,
    int? cargoUpgradeBonus,
    int? baseWeapons,
    int? weaponUpgradeBonus,
    int? price,
    int? cargoUpgradeCost,
    int? weaponUpgradeCost,
    double? speed,
    String? sprite,
    int? cargoUpgrades,
    int? weaponUpgrades,
    int? damage,
    String? currentPlanetId,
    bool? equipped,
    bool clearPlanet = false,
  }) {
    return Ship(
      id: id ?? this.id,
      typeId: typeId ?? this.typeId,
      name: name ?? this.name,
      baseCargo: baseCargo ?? this.baseCargo,
      cargoUpgradeBonus: cargoUpgradeBonus ?? this.cargoUpgradeBonus,
      baseWeapons: baseWeapons ?? this.baseWeapons,
      weaponUpgradeBonus: weaponUpgradeBonus ?? this.weaponUpgradeBonus,
      price: price ?? this.price,
      cargoUpgradeCost: cargoUpgradeCost ?? this.cargoUpgradeCost,
      weaponUpgradeCost: weaponUpgradeCost ?? this.weaponUpgradeCost,
      speed: speed ?? this.speed,
      sprite: sprite ?? this.sprite,
      cargoUpgrades: cargoUpgrades ?? this.cargoUpgrades,
      weaponUpgrades: weaponUpgrades ?? this.weaponUpgrades,
      damage: damage ?? this.damage,
      currentPlanetId: clearPlanet ? null : (currentPlanetId ?? this.currentPlanetId),
      equipped: equipped ?? this.equipped,
    );
  }
}
