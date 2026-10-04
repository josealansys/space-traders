/// Status of a loan.
enum LoanStatus {
  active,      // within deadline
  gracePeriod, // overdue but within grace
  overdue,     // past grace period, interest accruing
  repaid,
  defaulted,
}

/// A loan from a planet's bank.
class Loan {
  final String id;
  final String planetId; // bank that issued the loan
  final int principal;
  final double interestRate;
  final int deadlineTurn; // turn by which it must be repaid
  final int graceDeadlineTurn; // turn after which overdue interest kicks in
  final int amountRepaid;
  final LoanStatus status;
  final int takenOnTurn;

  const Loan({
    required this.id,
    required this.planetId,
    required this.principal,
    required this.interestRate,
    required this.deadlineTurn,
    required this.graceDeadlineTurn,
    this.amountRepaid = 0,
    this.status = LoanStatus.active,
    required this.takenOnTurn,
  });

  /// Total amount to repay (principal + interest).
  int get totalRepayAmount {
    return (principal * (1 + interestRate)).round();
  }

  /// How many turns until deadline (negative = overdue).
  int turnsUntilDeadline(int currentTurn) {
    return deadlineTurn - currentTurn;
  }

  /// Is this loan overdue?
  bool isOverdue(int currentTurn) {
    return currentTurn > deadlineTurn;
  }

  /// Is this loan in grace period?
  bool isInGracePeriod(int currentTurn) {
    return currentTurn > deadlineTurn && currentTurn <= graceDeadlineTurn;
  }

  /// Get current debt with accrued overdue interest.
  int getCurrentDebt(int currentTurn) {
    if (status == LoanStatus.repaid || status == LoanStatus.defaulted) {
      return 0;
    }
    int baseDebt = totalRepayAmount - amountRepaid;
    if (isInGracePeriod(currentTurn)) {
      return baseDebt; // no extra interest during grace
    }
    if (currentTurn > graceDeadlineTurn) {
      final overdueTurns = currentTurn - graceDeadlineTurn;
      final overdueInterest = (baseDebt * 0.10 * overdueTurns).round();
      return baseDebt + overdueInterest;
    }
    return baseDebt;
  }

  Loan copyWith({
    String? id,
    String? planetId,
    int? principal,
    double? interestRate,
    int? deadlineTurn,
    int? graceDeadlineTurn,
    int? amountRepaid,
    LoanStatus? status,
    int? takenOnTurn,
  }) {
    return Loan(
      id: id ?? this.id,
      planetId: planetId ?? this.planetId,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      deadlineTurn: deadlineTurn ?? this.deadlineTurn,
      graceDeadlineTurn: graceDeadlineTurn ?? this.graceDeadlineTurn,
      amountRepaid: amountRepaid ?? this.amountRepaid,
      status: status ?? this.status,
      takenOnTurn: takenOnTurn ?? this.takenOnTurn,
    );
  }
}
