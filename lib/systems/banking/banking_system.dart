import 'dart:math';
import '../../models/loan.dart';
import '../../models/planet.dart';
import '../../config/game_config.dart';

/// Result of a loan operation.
class LoanResult {
  final bool success;
  final String message;
  final Loan? loan;
  const LoanResult(this.success, this.message, {this.loan});
}

/// Per-planet banking system.
class BankingSystem {
  final Random _rng;

  BankingSystem({Random? rng}) : _rng = rng ?? Random();

  /// Take a loan from a planet's bank.
  ///
  /// Max loan = min(creditScore, GameConfig.maxLoanAmount).
  LoanResult takeLoan({
    required Planet planet,
    required int amount,
    required int currentTurn,
    required int creditScore,
  }) {
    if (amount <= 0) {
      return const LoanResult(false, 'Loan amount must be positive.');
    }

    final maxLoan = creditScore.clamp(0, GameConfig.maxLoanAmount);
    if (amount > maxLoan) {
      return LoanResult(
        false,
        'Loan denied. Max loan at your credit score ($creditScore) is $maxLoan cr.',
      );
    }

    final interest = (amount * GameConfig.loanInterestRate).round();
    final deadlineTurn = currentTurn + GameConfig.loanDeadlineTurns;
    final graceDeadlineTurn = deadlineTurn + GameConfig.loanGracePeriodTurns;

    final loan = Loan(
      id: 'loan_${planet.id}_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(99999)}',
      planetId: planet.id,
      principal: amount,
      interestRate: GameConfig.loanInterestRate,
      deadlineTurn: deadlineTurn,
      graceDeadlineTurn: graceDeadlineTurn,
      takenOnTurn: currentTurn,
    );

    return LoanResult(
      true,
      'Loan of $amount cr approved by ${planet.bankName}. '
      'Repay $interest cr interest by turn $deadlineTurn.',
      loan: loan,
    );
  }

  /// Repay a loan (full or partial).
  ///
  /// Returns (success, message, newLoan, amountPaid).
  ({bool success, String message, Loan? newLoan, int amountPaid}) repayLoan({
    required Loan loan,
    required int amount,
    required int availableCredits,
  }) {
    if (loan.status == LoanStatus.repaid || loan.status == LoanStatus.defaulted) {
      return (
        success: false,
        message: 'Loan is already closed.',
        newLoan: loan,
        amountPaid: 0,
      );
    }
    if (amount <= 0) {
      return (
        success: false,
        message: 'Repayment must be positive.',
        newLoan: loan,
        amountPaid: 0,
      );
    }
    if (amount > availableCredits) {
      return (
        success: false,
        message: 'Not enough credits.',
        newLoan: loan,
        amountPaid: 0,
      );
    }

    final totalDebt = loan.principal + (loan.principal * loan.interestRate).round() - loan.amountRepaid;
    final actualPayment = amount > totalDebt ? totalDebt : amount;
    final newRepaid = loan.amountRepaid + actualPayment;
    final isFullyRepaid = newRepaid >= (loan.principal + (loan.principal * loan.interestRate).round());

    final newLoan = loan.copyWith(
      amountRepaid: newRepaid,
      status: isFullyRepaid ? LoanStatus.repaid : loan.status,
    );

    return (
      success: true,
      message: isFullyRepaid
          ? 'Loan fully repaid. Credit score +200.'
          : 'Partial repayment: $actualPayment cr. Remaining: ${totalDebt - actualPayment} cr.',
      newLoan: newLoan,
      amountPaid: actualPayment,
    );
  }

  /// Update loan statuses at end of turn.
  ///
  /// Returns list of (loanId, newStatus).
  List<(String, LoanStatus)> updateLoanStatuses({
    required List<Loan> loans,
    required int currentTurn,
  }) {
    final updates = <(String, LoanStatus)>[];
    for (final loan in loans) {
      if (loan.status == LoanStatus.repaid || loan.status == LoanStatus.defaulted) continue;
      if (currentTurn > loan.graceDeadlineTurn) {
        updates.add((loan.id, LoanStatus.defaulted));
      } else if (currentTurn > loan.deadlineTurn) {
        updates.add((loan.id, LoanStatus.gracePeriod));
      } else if (loan.status != LoanStatus.active) {
        updates.add((loan.id, LoanStatus.active));
      }
    }
    return updates;
  }

  /// Get credit score tier label.
  static String getCreditTier(int score) {
    if (score >= 8000) return 'Excellent';
    if (score >= 6000) return 'Very Good';
    if (score >= 4000) return 'Good';
    if (score >= 2000) return 'Fair';
    return 'Poor';
  }

  /// Get credit score stars (0-5).
  static int getCreditStars(int score) {
    if (score >= 8000) return 5;
    if (score >= 6000) return 4;
    if (score >= 4000) return 3;
    if (score >= 2000) return 2;
    return 1;
  }
}
