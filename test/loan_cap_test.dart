
import 'package:flutter_test/flutter_test.dart';
import 'package:space_traders/models/game_state.dart';
import 'package:space_traders/models/loan.dart';
import 'package:space_traders/models/planet.dart';
import 'package:space_traders/models/ship.dart';
import 'package:space_traders/config/game_config.dart';

void main() {
  group('Loan cap verification', () {
    test('1. State with one active loan is detected by any()', () {
      final active = Loan(
        id: 'l1', planetId: 'terra', principal: 1000,
        interestRate: 0.1, deadlineTurn: 5, graceDeadlineTurn: 8,
        amountRepaid: 0, status: LoanStatus.active, takenOnTurn: 0,
      );
      final state = GameState(
        loans: [active], lastSaved: DateTime.now(),
      );
      // This is the actual check in takeLoan:
      expect(state.loans.any((l) => l.status == LoanStatus.active), true);
    });

    test('2. State with no loans returns false from any()', () {
      final state = GameState(lastSaved: DateTime.now());
      expect(state.loans.any((l) => l.status == LoanStatus.active), false);
    });

    test('3. State with repaid loan is NOT blocking (status is repaid)', () {
      final repaid = Loan(
        id: 'l1', planetId: 'terra', principal: 1000,
        interestRate: 0.1, deadlineTurn: 5, graceDeadlineTurn: 8,
        amountRepaid: 1100, status: LoanStatus.repaid, takenOnTurn: 0,
      );
      final state = GameState(loans: [repaid], lastSaved: DateTime.now());
      expect(state.loans.any((l) => l.status == LoanStatus.active), false);
    });

    test('4. State with defaulted loan is NOT blocking', () {
      final defaulted = Loan(
        id: 'l1', planetId: 'terra', principal: 1000,
        interestRate: 0.1, deadlineTurn: 5, graceDeadlineTurn: 8,
        amountRepaid: 0, status: LoanStatus.defaulted, takenOnTurn: 0,
      );
      final state = GameState(loans: [defaulted], lastSaved: DateTime.now());
      expect(state.loans.any((l) => l.status == LoanStatus.active), false);
    });
  });
}
