import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../../game/game_state_controller.dart';
import '../../models/planet.dart';
import '../../models/crew.dart';
import '../../models/cargo.dart';

class WarehouseTab extends ConsumerStatefulWidget {
  final Planet planet;
  const WarehouseTab({required this.planet, super.key});

  @override
  ConsumerState<WarehouseTab> createState() => _WarehouseTabState();
}

class _WarehouseTabState extends ConsumerState<WarehouseTab> {
  final _crewNameController = TextEditingController(text: 'Crew');
  final _fundingController = TextEditingController(text: '1000');

  @override
  void dispose() {
    _crewNameController.dispose();
    _fundingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final planetCrews = state.crews.where((c) => c.planetId == widget.planet.id).toList();
    final planetWarehouse = state.warehouseCargo[widget.planet.id] ?? <Cargo>[];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warehouse, color: AppTheme.warning, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${widget.planet.name} Warehouse',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${planetCrews.length} crews • ${planetWarehouse.length} cargo types',
                          style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Hire crew
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HIRE AI CREW',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text('AI crews auto-trade cargo on this planet.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
                const SizedBox(height: 12),
                TextField(
                  controller: _crewNameController,
                  decoration: const InputDecoration(
                    labelText: 'Crew name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fundingController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Initial funding (cr)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = _crewNameController.text.isEmpty
                          ? 'Crew ${planetCrews.length + 1}'
                          : _crewNameController.text;
                      final funding = int.tryParse(_fundingController.text) ?? 0;
                      if (state.credits < funding) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Not enough credits.')),
                        );
                        return;
                      }
                      if (planetCrews.length >= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Max 3 crews per planet.')),
                        );
                        return;
                      }
                      ref.read(gameStateProvider.notifier).hireCrew(widget.planet.id, name, funding);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$name hired with $funding cr funding.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                    child: const Text('HIRE CREW'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Active crews
        if (planetCrews.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('CREWS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          ...planetCrews.map((c) => _CrewCard(crew: c, planet: this.widget.planet)),
        ],

        // Stored cargo
        if (planetWarehouse.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('WAREHOUSE CARGO',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          ...planetWarehouse.map((c) => Card(
                child: ListTile(
                  leading: const Icon(Icons.inventory_2, color: AppTheme.primary),
                  title: Text(c.commodityId),
                  trailing: Text('${c.quantity} units'),
                ),
              )),
        ],
      ],
    );
  }
}

class _CrewCard extends ConsumerWidget {
  final Crew crew;
  final Planet planet;
  const _CrewCard({required this.crew, required this.planet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.warning.withOpacity(0.2),
                  child: const Icon(Icons.smart_toy, color: AppTheme.warning, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(crew.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: crew.status == CrewStatus.active
                        ? AppTheme.success.withOpacity(0.2)
                        : AppTheme.textDim.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(crew.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: crew.status == CrewStatus.active ? AppTheme.success : AppTheme.textDim,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Funding: ${crew.funding} cr  •  Skill: ${(crew.skill * 100).round()}%',
                style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
            if (crew.history.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('RECENT ACTIVITY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              ...crew.history.reversed.take(3).map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${t.isBuy ? "Bought" : "Sold"} ${t.quantity}x ${t.commodityId} @ ${t.pricePerUnit}cr — ${t.reason}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  )),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(gameStateProvider.notifier).fundCrew(crew.id, 500);
                    },
                    child: const Text('+500 cr', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(gameStateProvider.notifier).fundCrew(crew.id, 2000);
                    },
                    child: const Text('+2000 cr', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
