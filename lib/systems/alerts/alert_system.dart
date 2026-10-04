import 'package:uuid/uuid.dart';
import '../../models/alert.dart';
import '../../models/loan.dart';
import '../../models/mission.dart';
import '../../config/game_config.dart';

class AlertSystem {
  final Uuid _uuid = const Uuid();

  /// Generate all alerts for the current turn.
  List<Alert> generateAlerts({
    required int currentTurn,
    required List<Loan> loans,
    required List<Mission> missions,
  }) {
    final alerts = <Alert>[];

    // Loan alerts
    for (final loan in loans) {
      if (loan.status == LoanStatus.repaid || loan.status == LoanStatus.defaulted) continue;

      final turnsUntilDeadline = loan.deadlineTurn - currentTurn;
      final turnsUntilGrace = loan.graceDeadlineTurn - currentTurn;

      if (turnsUntilDeadline == GameConfig.alertAdvanceTurns) {
        alerts.add(Alert(
          id: _uuid.v4(),
          type: AlertType.loan,
          severity: AlertSeverity.warning,
          title: 'Loan Due Soon',
          message: 'Loan from ${loan.planetId} due in $turnsUntilDeadline turns. '
              'Repay ${loan.getCurrentDebt(currentTurn)} cr.',
          actionRoute: 'planet/${loan.planetId}/bank',
          turn: currentTurn,
        ));
      } else if (turnsUntilDeadline == 1) {
        alerts.add(Alert(
          id: _uuid.v4(),
          type: AlertType.loan,
          severity: AlertSeverity.urgent,
          title: 'Loan Due Tomorrow',
          message: 'URGENT: Loan payment due in 1 turn! '
              'Amount: ${loan.getCurrentDebt(currentTurn)} cr.',
          actionRoute: 'planet/${loan.planetId}/bank',
          turn: currentTurn,
        ));
      } else if (turnsUntilDeadline == 0) {
        alerts.add(Alert(
          id: _uuid.v4(),
          type: AlertType.loan,
          severity: AlertSeverity.critical,
          title: 'Loan Due Now',
          message: 'Loan payment is due THIS turn. '
              'Amount: ${loan.getCurrentDebt(currentTurn)} cr.',
          actionRoute: 'planet/${loan.planetId}/bank',
          turn: currentTurn,
        ));
      } else if (turnsUntilDeadline < 0 && turnsUntilGrace > 0) {
        if (turnsUntilGrace == 2) {
          alerts.add(Alert(
            id: _uuid.v4(),
            type: AlertType.loan,
            severity: AlertSeverity.warning,
            title: 'Loan in Grace Period',
            message: 'Loan overdue. Grace period ends in $turnsUntilGrace turns. '
                'No extra interest yet.',
            actionRoute: 'planet/${loan.planetId}/bank',
            turn: currentTurn,
          ));
        } else if (turnsUntilGrace == 0) {
          alerts.add(Alert(
            id: _uuid.v4(),
            type: AlertType.loan,
            severity: AlertSeverity.critical,
            title: 'Grace Period Ended',
            message: 'Overdue interest now accruing at 10% per turn. '
                'Pay ASAP: ${loan.getCurrentDebt(currentTurn)} cr.',
            actionRoute: 'planet/${loan.planetId}/bank',
            turn: currentTurn,
          ));
        }
      } else if (turnsUntilGrace < 0) {
        alerts.add(Alert(
          id: _uuid.v4(),
          type: AlertType.loan,
          severity: AlertSeverity.critical,
          title: 'Loan DEFAULTED',
          message: 'Loan is in default. Massive interest penalty. '
              'Owed: ${loan.getCurrentDebt(currentTurn)} cr.',
          actionRoute: 'planet/${loan.planetId}/bank',
          turn: currentTurn,
        ));
      }
    }

    // Mission alerts
    for (final mission in missions) {
      if (mission.status != MissionStatus.active) continue;

      final turnsUntilDeadline = mission.deadlineTurn - currentTurn;

      if (turnsUntilDeadline == GameConfig.alertAdvanceTurns) {
        alerts.add(Alert(
          id: _uuid.v4(),
          type: AlertType.mission,
          severity: AlertSeverity.warning,
          title: 'Mission Due Soon',
          message: '${mission.governorName}\'s mission due in $turnsUntilDeadline turns. '
              'Deliver ${mission.quantity} units.',
          actionRoute: 'planet/${mission.planetId}/government',
          turn: currentTurn,
        ));
      } else if (turnsUntilDeadline == 1) {
        alerts.add(Alert(
          id: _uuid.v4(),
          type: AlertType.mission,
          severity: AlertSeverity.urgent,
          title: 'Mission Due Tomorrow',
          message: 'URGENT: ${mission.description} (1 turn left!)',
          actionRoute: 'planet/${mission.planetId}/government',
          turn: currentTurn,
        ));
      } else if (turnsUntilDeadline <= 0) {
        alerts.add(Alert(
          id: _uuid.v4(),
          type: AlertType.mission,
          severity: AlertSeverity.critical,
          title: 'Mission FAILED',
          message: 'Deadline passed: ${mission.description}',
          turn: currentTurn,
        ));
      }
    }

    return alerts;
  }
}
