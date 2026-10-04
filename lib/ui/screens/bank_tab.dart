import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../../game/game_state_controller.dart';
import '../../systems/banking/banking_system.dart';
import '../../models/loan.dart';
import '../../models/planet.dart';
import '../../config/game_config.dart';

class BankTab extends ConsumerStatefulWidget {
  final Planet planet;
  const BankTab({required this.planet, super.key});

  @override
  ConsumerState<BankTab> createState() => _BankTabState();
}

class _BankTabState extends ConsumerState<BankTab> {
  final _loanAmountController = TextEditingController(text: '1000');
  final _repayAmountController = TextEditingController(text: '0');

  @override
  void dispose() {
    _loanAmountController.dispose();
    _repayAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameStateProvider);
    final banking = ref.read(bankingSystemProvider);
    final planetLoans = state.loans.where((l) => l.planetId == widget.planet.id).toList();
    final stars = BankingSystem.getCreditStars(state.creditScore);
    final tier = BankingSystem.getCreditTier(state.creditScore);
    final maxLoan = state.creditScore.clamp(0, GameConfig.maxLoanAmount);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Bank header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance, color: AppTheme.accent, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.planet.bankName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(widget.planet.name,
                              style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Credit Score: ${state.creditScore}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    ...List.generate(5, (i) => Icon(
                      Icons.star,
                      size: 16,
                      color: i < stars ? AppTheme.accent : AppTheme.textDim.withOpacity(0.3),
                    )),
                    const Spacer(),
                    Text(tier, style: TextStyle(color: AppTheme.accent)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Max loan at current score: $maxLoan cr',
                    style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Take loan section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TAKE LOAN',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                TextField(
                  controller: _loanAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (cr)',
                    border: const OutlineInputBorder(),
                    suffixText: 'cr',
                    helperText: '10% interest, due in 5 turns',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = int.tryParse(_loanAmountController.text) ?? 0;
                      final result = ref.read(gameStateProvider.notifier).takeLoan(widget.planet.id, amount);
                      if (result) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Loan approved!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Loan denied.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                    child: const Text('BORROW'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Active loans at this planet
        if (planetLoans.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('ACTIVE LOANS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
          ...planetLoans.map((loan) => _LoanCard(loan: loan, planet: widget.planet)),
        ],
      ],
    );
  }
}

class _LoanCard extends ConsumerWidget {
  final Loan loan;
  final Planet planet;
  const _LoanCard({required this.loan, required this.planet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameStateProvider);
    final currentDebt = loan.getCurrentDebt(state.turn);
    final turnsLeft = loan.deadlineTurn - state.turn;
    final isOverdue = state.turn > loan.deadlineTurn;
    final isInGrace = state.turn > loan.graceDeadlineTurn;

    Color statusColor = AppTheme.success;
    String statusText = '$turnsLeft turns left';
    if (isInGrace) {
      statusColor = AppTheme.danger;
      statusText = 'DEFAULTED';
    } else if (isOverdue) {
      statusColor = AppTheme.warning;
      final graceLeft = loan.graceDeadlineTurn - state.turn;
      statusText = 'OVERDUE ($graceLeft grace turns)';
    } else if (turnsLeft <= 2) {
      statusColor = AppTheme.warning;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${loan.principal} cr loan',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(statusText,
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Owed: $currentDebt cr  •  Interest: 10%  •  Grace: 3 turns',
                style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.credits > 0
                        ? () {
                            final paid = ref.read(gameStateProvider.notifier).repayLoan(loan.id, currentDebt);
                            if (paid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Repaid $currentDebt cr. +200 credit score.')),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    child: Text('REPAY $currentDebt cr'),
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
