import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../painters/planet_painter.dart';
import '../../game/game_state_controller.dart';

/// Travel screen — pick a destination planet.
class TravelScreen extends ConsumerWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final planetsAsync = ref.watch(planetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('TRAVEL')),
      body: planetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (planets) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: planets.length,
            itemBuilder: (context, i) {
              final planet = planets[i];
              final isCurrent = planet.id == state.currentPlanetId;
              final canAfford = state.credits >= planet.travelCost;

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: isCurrent || !canAfford
                      ? null
                      : () {
                          ref.read(gameStateProvider.notifier).travelTo(planet.id);
                          Navigator.of(context).pop();
                        },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CustomPaint(
                            painter: PlanetPainter(planet: planet, pulse: i.isEven ? 0.5 : 0.0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(planet.name,
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold)),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.success.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text('HERE',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: AppTheme.success,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(planet.description,
                                  style: TextStyle(
                                      fontSize: 11, color: AppTheme.textDim),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(
                                'Cost: ${planet.travelCost} cr',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: canAfford ? AppTheme.text : AppTheme.danger,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrent)
                          Icon(
                            canAfford ? Icons.arrow_forward : Icons.lock,
                            color: canAfford ? AppTheme.primary : AppTheme.textDim,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
