import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../painters/ship_painter.dart';
import '../../game/game_state_controller.dart';
import '../../models/ship.dart';
import '../../config/game_config.dart';
import '../../data/data_loader.dart';

class FleetTab extends ConsumerStatefulWidget {
  const FleetTab({super.key});

  @override
  ConsumerState<FleetTab> createState() => _FleetTabState();
}

class _FleetTabState extends ConsumerState<FleetTab> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final ships = state.ships;
    final equipped = ships.where((s) => s.equipped).toList();
    final stored = ships.where((s) => !s.equipped).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Stats
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(label: 'OWNED', value: '${ships.length}/${GameConfig.maxShipsOwned}', color: AppTheme.primary),
                _Stat(label: 'EQUIPPED', value: '${equipped.length}/${GameConfig.maxShipsEquipped}', color: AppTheme.success),
                _Stat(label: 'FLYING', value: '${state.flyingShips.length}/${GameConfig.maxShipsFlying}', color: AppTheme.accent),
                _Stat(label: 'STORED', value: '${stored.length}/${GameConfig.maxShipsStored}', color: AppTheme.textDim),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Shipyard
        Card(
          child: ListTile(
            leading: const Icon(Icons.add_business, color: AppTheme.accent),
            title: const Text('SHIPYARD'),
            subtitle: const Text('Buy new ships'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showShipyard(context),
          ),
        ),
        const SizedBox(height: 12),

        // Equipped ships
        if (equipped.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('ACTIVE FLEET',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          ...equipped.map((s) => _ShipCard(ship: s, isActive: s.id == state.activeShipId)),
        ],
        if (stored.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('STORED SHIPS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          ...stored.map((s) => _ShipCard(ship: s, isActive: false)),
        ],
      ],
    );
  }

  void _showShipyard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      builder: (_) => const _ShipyardSheet(),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textDim, letterSpacing: 1)),
      ],
    );
  }
}

class _ShipCard extends ConsumerWidget {
  final Ship ship;
  final bool isActive;
  const _ShipCard({required this.ship, required this.isActive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final cargo = state.shipCargo[ship.id] ?? [];
    final usedSpace = cargo.fold<int>(0, (s, c) => s + c.quantity);
    final capacity = ship.cargoCapacity;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CustomPaint(
                    painter: ShipPainter(ship: ship, damaged: ship.isDamaged, thrust: 0.6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(ship.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          if (isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text('ACTIVE',
                                  style: TextStyle(fontSize: 9, color: AppTheme.success, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text('${ship.typeId.toUpperCase()}  •  ${ship.totalInvested}cr invested',
                          style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
                    ],
                  ),
                ),
                if (ship.isDamaged)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${ship.damage}% DMG',
                        style: const TextStyle(fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ShipStat(label: 'Cargo', value: '$usedSpace/$capacity', progress: usedSpace / capacity),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShipStat(label: 'Weapons', value: '${ship.totalWeapons}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShipStat(label: 'Speed', value: '${(ship.speed * 100).round()}%'),
                ),
              ],
            ),
            if (ship.cargoUpgrades > 0 || ship.weaponUpgrades > 0) ...[
              const SizedBox(height: 4),
              Text('Upgrades: +${ship.cargoUpgrades * 5} cargo, +${ship.weaponUpgrades} weapons',
                  style: TextStyle(fontSize: 10, color: AppTheme.accent)),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (ship.isDamaged)
                  ElevatedButton(
                    onPressed: state.credits >= ship.repairCost
                        ? () {
                            ref.read(gameStateProvider.notifier).repairShip(ship.id);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: Text('REPAIR (${ship.repairCost}cr)',
                        style: const TextStyle(fontSize: 10)),
                  ),
                ElevatedButton(
                  onPressed: state.credits >= ship.cargoUpgradeCost && ship.cargoUpgrades < 5
                      ? () => ref.read(gameStateProvider.notifier).upgradeShipCargo(ship.id)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 28),
                  ),
                  child: Text('+CARGO (${ship.cargoUpgradeCost}cr)',
                      style: const TextStyle(fontSize: 10)),
                ),
                ElevatedButton(
                  onPressed: state.credits >= ship.weaponUpgradeCost && ship.weaponUpgrades < 5
                      ? () => ref.read(gameStateProvider.notifier).upgradeShipWeapons(ship.id)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 28),
                  ),
                  child: Text('+WEAPON (${ship.weaponUpgradeCost}cr)',
                      style: const TextStyle(fontSize: 10)),
                ),
                if (!isActive && ship.equipped && ship.currentPlanetId == null)
                  ElevatedButton(
                    onPressed: () => ref.read(gameStateProvider.notifier).setActiveShip(ship.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                    ),
                    child: const Text('PILOT', style: TextStyle(fontSize: 10)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipStat extends StatelessWidget {
  final String label;
  final String value;
  final double? progress;
  const _ShipStat({required this.label, required this.value, this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textDim)),
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: progress!.clamp(0.0, 1.0),
            backgroundColor: AppTheme.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 4,
          ),
        ],
      ],
    );
  }
}

class _ShipyardSheet extends ConsumerWidget {
  const _ShipyardSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          color: AppTheme.surface,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: DataLoader.loadShips(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final state = ref.watch(gameStateProvider);
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('SHIPYARD',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                  ...snap.data!.map((shipData) {
                    final price = shipData['price'] as int;
                    final canBuy = state.credits >= price && state.ships.length < GameConfig.maxShipsOwned;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: CustomPaint(
                                painter: ShipPainter(
                                  ship: Ship(
                                    id: 'preview',
                                    typeId: shipData['id'],
                                    name: shipData['name'],
                                    baseCargo: shipData['baseCargo'],
                                    cargoUpgradeBonus: shipData['cargoUpgradeBonus'],
                                    baseWeapons: shipData['baseWeapons'],
                                    weaponUpgradeBonus: 0,
                                    price: shipData['price'],
                                    cargoUpgradeCost: shipData['cargoUpgradeCost'],
                                    weaponUpgradeCost: shipData['weaponUpgradeCost'],
                                    speed: (shipData['speed'] as num).toDouble(),
                                    sprite: shipData['sprite'],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(shipData['name'],
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(shipData['description'],
                                      style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Cargo +${shipData['cargoUpgradeBonus']}  •  Weapons ${shipData['baseWeapons']}  •  Speed ${((shipData['speed'] as num) * 100).round()}%',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: canBuy
                                  ? () {
                                      final fleet = ref.read(fleetSystemProvider);
                                      final newShip = fleet.buyShip(
                                        typeId: shipData['id'],
                                        name: shipData['name'],
                                        baseCargo: shipData['baseCargo'],
                                        cargoUpgradeBonus: shipData['cargoUpgradeBonus'],
                                        baseWeapons: shipData['baseWeapons'],
                                        price: shipData['price'],
                                        cargoUpgradeCost: shipData['cargoUpgradeCost'],
                                        weaponUpgradeCost: shipData['weaponUpgradeCost'],
                                        speed: (shipData['speed'] as num).toDouble(),
                                        sprite: shipData['sprite'],
                                      );
                                      ref.read(gameStateProvider.notifier).buyShip(newShip);
                                      Navigator.of(context).pop();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                              child: Text('${shipData['price']} cr'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
