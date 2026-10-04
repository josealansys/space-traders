import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/game_state.dart';
import '../../config/game_config.dart';

class SaveSlot {
  final int index;
  final String name;
  final DateTime savedAt;
  final int turn;
  final int credits;
  final String? planetName;

  const SaveSlot({
    required this.index,
    required this.name,
    required this.savedAt,
    required this.turn,
    required this.credits,
    this.planetName,
  });
}

/// Save/load system using SharedPreferences (works on web + native).
class SaveSystem {
  static const _keyPrefix = 'space_traders_save_';

  /// Save game state to a slot (0-4).
  Future<bool> save({required int slot, required String name, required GameState state}) async {
    if (slot < 0 || slot >= GameConfig.maxSaveSlots) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode({
        'version': state.saveVersion,
        'name': name,
        'turn': state.turn,
        'credits': state.credits,
        'creditScore': state.creditScore,
        'bounty': state.bounty,
        'currentPlanetId': state.currentPlanetId,
        'activeShipId': state.activeShipId,
        'ships': state.ships.map((s) => {
              'id': s.id,
              'typeId': s.typeId,
              'name': s.name,
              'baseCargo': s.baseCargo,
              'cargoUpgradeBonus': s.cargoUpgradeBonus,
              'baseWeapons': s.baseWeapons,
              'weaponUpgradeBonus': s.weaponUpgradeBonus,
              'price': s.price,
              'cargoUpgradeCost': s.cargoUpgradeCost,
              'weaponUpgradeCost': s.weaponUpgradeCost,
              'speed': s.speed,
              'sprite': s.sprite,
              'cargoUpgrades': s.cargoUpgrades,
              'weaponUpgrades': s.weaponUpgrades,
              'damage': s.damage,
              'currentPlanetId': s.currentPlanetId,
              'equipped': s.equipped,
            }).toList(),
        'loans': state.loans.map((l) => {
              'id': l.id,
              'planetId': l.planetId,
              'principal': l.principal,
              'interestRate': l.interestRate,
              'deadlineTurn': l.deadlineTurn,
              'graceDeadlineTurn': l.graceDeadlineTurn,
              'amountRepaid': l.amountRepaid,
              'status': l.status.name,
              'takenOnTurn': l.takenOnTurn,
            }).toList(),
        'missions': state.missions.map((m) => {
              'id': m.id,
              'planetId': m.planetId,
              'governorName': m.governorName,
              'description': m.description,
              'commodityId': m.commodityId,
              'quantity': m.quantity,
              'rewardCredits': m.rewardCredits,
              'rewardCreditScore': m.rewardCreditScore,
              'acceptedOnTurn': m.acceptedOnTurn,
              'deadlineTurn': m.deadlineTurn,
              'status': m.status.name,
            }).toList(),
        'priceModifiers': state.priceModifiers,
        'priceLastRollTurn': state.priceLastRollTurn,
        'savedAt': DateTime.now().toIso8601String(),
      });
      await prefs.setString('$_keyPrefix$slot', json);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Load game state from a slot.
  Future<GameState?> load(int slot) async {
    if (slot < 0 || slot >= GameConfig.maxSaveSlots) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$slot');
      if (raw == null) return null;
      // Parse and reconstruct GameState
      // (Full reconstruction would need model.fromJson for all types —
      // this is a minimal stub for the save format)
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return GameState(
        turn: data['turn'] as int? ?? 0,
        credits: data['credits'] as int? ?? 0,
        creditScore: data['creditScore'] as int? ?? 0,
        bounty: data['bounty'] as int? ?? 0,
        currentPlanetId: data['currentPlanetId'] as String? ?? 'terra',
        saveName: data['name'] as String? ?? 'Save $slot',
        lastSaved: DateTime.tryParse(data['savedAt'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// List all save slots.
  Future<List<SaveSlot>> listSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final slots = <SaveSlot>[];
    for (int i = 0; i < GameConfig.maxSaveSlots; i++) {
      final raw = prefs.getString('$_keyPrefix$i');
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          slots.add(SaveSlot(
            index: i,
            name: data['name'] as String? ?? 'Save $i',
            savedAt: DateTime.tryParse(data['savedAt'] as String? ?? '') ?? DateTime.now(),
            turn: data['turn'] as int? ?? 0,
            credits: data['credits'] as int? ?? 0,
          ));
        } catch (_) {
          // Corrupt save, skip
        }
      } else {
        slots.add(SaveSlot(
          index: i,
          name: 'Empty Slot',
          savedAt: DateTime.fromMillisecondsSinceEpoch(0),
          turn: 0,
          credits: 0,
        ));
      }
    }
    return slots;
  }

  /// Delete a save slot.
  Future<bool> delete(int slot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('$_keyPrefix$slot');
    } catch (_) {
      return false;
    }
  }
}
