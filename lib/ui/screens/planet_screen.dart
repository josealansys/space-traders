import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../painters/planet_painter.dart';
import '../painters/cargo_icon_painter.dart';
import '../../game/game_state_controller.dart';
import '../../models/planet.dart';
import '../../models/commodity.dart';
import '../../models/cargo.dart';
import '../../systems/trading/trading_system.dart';
import 'travel_screen.dart';
import 'bank_tab.dart';
import 'government_tab.dart';
import 'warehouse_tab.dart';
import 'fleet_tab.dart';

class PlanetScreen extends ConsumerStatefulWidget {
  const PlanetScreen({super.key});

  @override
  ConsumerState<PlanetScreen> createState() => _PlanetScreenState();
}

class _PlanetScreenState extends ConsumerState<PlanetScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final planetsAsync = ref.watch(planetsProvider);
    final commoditiesAsync = ref.watch(commoditiesProvider);

    return planetsAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.danger))),
      ),
      data: (planets) {
        final currentPlanet = planets.firstWhere(
          (p) => p.id == state.currentPlanetId,
          orElse: () => planets.first,
        );

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: AppTheme.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: _PremiumAppBar(state: state),
          ),
          body: Stack(
            children: [
              // Starfield background
              Positioned.fill(
                child: CustomPaint(painter: StarfieldPainter(seed: 7, density: 0.5)),
              ),
              Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 60),
                  // Planet header (animated)
                  _PlanetHeader(planet: currentPlanet, state: state),
                  // Tabs
                  _TabBar(
                    current: _tabIndex,
                    onTap: (i) => setState(() => _tabIndex = i),
                  ),
                  // Tab content
                  Expanded(
                    child: commoditiesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (commodities) {
                        switch (_tabIndex) {
                          case 0: return _MarketTab(planet: currentPlanet, commodities: commodities);
                          case 1: return BankTab(planet: currentPlanet);
                          case 2: return GovernmentTab(planet: currentPlanet);
                          case 3: return WarehouseTab(planet: currentPlanet);
                          case 4: return const FleetTab();
                          default: return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: _TravelFAB(planet: currentPlanet, state: state),
        );
      },
    );
  }
}

class _PremiumAppBar extends StatelessWidget {
  final state;
  const _PremiumAppBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.background.withOpacity(0.7),
      title: const Text('SPACE TRADERS'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              StatChip(
                icon: Icons.account_balance_wallet,
                label: '${state.credits}',
                color: AppTheme.success,
                tooltip: 'Credits',
              ),
              const SizedBox(width: 8),
              StatChip(
                icon: Icons.star,
                label: '${state.creditScore}',
                color: AppTheme.accent,
                tooltip: 'Credit Score',
              ),
              const SizedBox(width: 8),
              StatChip(
                icon: Icons.access_time,
                label: 'T${state.turn}',
                color: AppTheme.primary,
                tooltip: 'Turn',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanetHeader extends StatefulWidget {
  final Planet planet;
  final state;
  const _PlanetHeader({required this.planet, required this.state});

  @override
  State<_PlanetHeader> createState() => _PlanetHeaderState();
}

class _PlanetHeaderState extends State<_PlanetHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GlassCard(
        padding: EdgeInsets.zero,
        gradient: LinearGradient(
          colors: [
            widget.planet.color.withOpacity(0.3),
            AppTheme.surface,
            AppTheme.surfaceDeep,
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => CustomPaint(
                  painter: PlanetPainter(
                    planet: widget.planet,
                    pulse: 0.3 + 0.3 * _controller.value,
                    rotation: _controller.value,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.planet.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppTheme.textBright,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _governmentLabel(widget.planet),
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.planet.color,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.planet.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textDim,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: widget.planet.specialties
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.15),
                                  border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppTheme.accent,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _governmentLabel(Planet p) {
    return p.governmentType.name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]!.toLowerCase()}')
        .trim()
        .toUpperCase();
  }
}

class _TabBar extends StatelessWidget {
  final int current;
  final void Function(int) onTap;
  const _TabBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      _TabInfo('MARKET', Icons.storefront),
      _TabInfo('BANK', Icons.account_balance),
      _TabInfo('GOV', Icons.account_box),
      _TabInfo('WAREHOUSE', Icons.warehouse),
      _TabInfo('FLEET', Icons.directions_boat),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.5),
        border: Border.all(color: AppTheme.surfaceLight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = current == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: active ? AppTheme.primaryGradient : null,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[i].icon,
                      size: 16,
                      color: active ? AppTheme.background : AppTheme.textDim,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tabs[i].label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: active ? AppTheme.background : AppTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  const _TabInfo(this.label, this.icon);
}

class _TravelFAB extends StatelessWidget {
  final Planet planet;
  final state;
  const _TravelFAB({required this.planet, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TravelScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.rocket_launch, color: AppTheme.background, size: 20),
                const SizedBox(width: 8),
                Text(
                  'TRAVEL  •  ${planet.travelCost}cr',
                  style: const TextStyle(
                    color: AppTheme.background,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// === MARKET TAB ===

class _MarketTab extends ConsumerWidget {
  final Planet planet;
  final List<Commodity> commodities;
  const _MarketTab({required this.planet, required this.commodities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final tradingSystem = ref.watch(tradingSystemProvider);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      itemCount: commodities.length,
      itemBuilder: (context, i) {
        final commodity = commodities[i];
        final price = tradingSystem.calculatePrice(
          planet: planet,
          commodity: commodity,
          currentTurn: state.turn,
          modifiers: state.priceModifiers,
          lastRollTurn: state.priceLastRollTurn,
        );

        final ship = state.activeShip;
        final currentCargo = state.shipCargo[ship?.id] ?? [];
        final ownedQty = currentCargo
            .firstWhere(
              (c) => c.commodityId == commodity.id,
              orElse: () => Cargo(commodityId: commodity.id, quantity: 0),
            )
            .quantity;

        return _MarketCard(
          commodity: commodity,
          price: price,
          ownedQty: ownedQty,
          planet: planet,
          onBuy: () => ref.read(gameStateProvider.notifier).buyCargo(
            commodity.id, 1, price.currentPrice,
          ),
          onSell: ownedQty > 0
              ? () => ref.read(gameStateProvider.notifier).sellCargo(
                  commodity.id, 1, price.currentPrice,
                )
              : null,
        );
      },
    );
  }
}

class _MarketCard extends StatelessWidget {
  final Commodity commodity;
  final MarketPrice price;
  final int ownedQty;
  final Planet planet;
  final VoidCallback onBuy;
  final VoidCallback? onSell;

  const _MarketCard({
    required this.commodity,
    required this.price,
    required this.ownedQty,
    required this.planet,
    required this.onBuy,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = AppTheme.tierColor(price.tierLabel);
    final profit = price.currentPrice - price.basePrice;
    final isProfit = profit > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        gradient: LinearGradient(
          colors: [
            tierColor.withOpacity(0.08),
            AppTheme.surface,
          ],
        ),
        borderColor: tierColor.withOpacity(0.3),
        child: Row(
          children: [
            // Cargo icon
            SizedBox(
              width: 52,
              height: 52,
              child: CustomPaint(
                painter: CargoIconPainter(commodity: commodity, highlighted: true),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          commodity.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textBright,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TierBadge(label: price.tierLabel, color: tierColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${price.currentPrice}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: tierColor,
                        ),
                      ),
                      Text(
                        ' cr',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textDim,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: (isProfit ? AppTheme.danger : AppTheme.success).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${isProfit ? '+' : ''}${profit}cr',
                          style: TextStyle(
                            fontSize: 10,
                            color: isProfit ? AppTheme.danger : AppTheme.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Base ${price.basePrice}  •  Owned: $ownedQty  •  ${price.stockIcon} ${(price.percentOfBase * 100 - 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action buttons
            Column(
              children: [
                _MiniButton(
                  label: 'BUY',
                  gradient: AppTheme.successGradient,
                  onTap: onBuy,
                ),
                const SizedBox(height: 4),
                _MiniButton(
                  label: 'SELL',
                  gradient: AppTheme.dangerGradient,
                  onTap: onSell,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TierBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.6), width: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback? onTap;
  const _MiniButton({required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.3,
      child: Container(
        width: 56,
        height: 26,
        decoration: BoxDecoration(
          gradient: enabled ? gradient : null,
          color: enabled ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? AppTheme.background : AppTheme.textDim,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
