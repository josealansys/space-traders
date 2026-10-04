import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../../game/game_state_controller.dart';
import '../../models/planet.dart';
import '../../models/mission.dart';

class GovernmentTab extends ConsumerStatefulWidget {
  final Planet planet;
  const GovernmentTab({required this.planet, super.key});

  @override
  ConsumerState<GovernmentTab> createState() => _GovernmentTabState();
}

class _GovernmentTabState extends ConsumerState<GovernmentTab> {
  @override
  void initState() {
    super.initState();
    // Auto-generate missions for this planet when tab opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).generateMissionsForCurrentPlanet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final allMissions = state.missions.where((m) => m.planetId == widget.planet.id).toList();
    final available = allMissions.where((m) => m.status == MissionStatus.available).toList();
    final active = allMissions.where((m) => m.status == MissionStatus.active).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Governor header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                  child: const Icon(Icons.person, color: AppTheme.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.planet.governorName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Governor of ${widget.planet.name}',
                          style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
                      const SizedBox(height: 4),
                      Text(
                        widget.planet.governmentType.name
                            .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]!.toLowerCase()}')
                            .trim()
                            .toUpperCase(),
                        style: TextStyle(fontSize: 10, color: AppTheme.accent, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Available missions
        if (available.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('AVAILABLE MISSIONS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          ...available.map((m) => _MissionCard(mission: m)),
        ],

        // Active missions
        if (active.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('ACTIVE MISSIONS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          ...active.map((m) => _MissionCard(mission: m, active: true)),
        ],

        if (available.isEmpty && active.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('No missions available from this governor.',
                  style: TextStyle(color: AppTheme.textDim)),
            ),
          ),
      ],
    );
  }
}

class _MissionCard extends ConsumerWidget {
  final Mission mission;
  final bool active;
  const _MissionCard({required this.mission, this.active = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final turnsLeft = mission.deadlineTurn - state.turn;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: active ? AppTheme.warning : AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(mission.description,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _Chip(label: 'Deliver ${mission.quantity}', icon: Icons.inventory_2),
                _Chip(label: 'Reward: ${mission.rewardCredits} cr', icon: Icons.attach_money, color: AppTheme.success),
                _Chip(label: 'Credit: +${mission.rewardCreditScore}', icon: Icons.star, color: AppTheme.accent),
                if (active) _Chip(label: '$turnsLeft turns left', icon: Icons.access_time, color: turnsLeft <= 2 ? AppTheme.danger : AppTheme.warning),
              ],
            ),
            if (!active) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(gameStateProvider.notifier).acceptMission(mission.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mission accepted!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  child: const Text('ACCEPT MISSION'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  const _Chip({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
