/// Alert severity level.
enum AlertSeverity {
  info,      // general notice
  warning,   // heads up (2 turns before)
  urgent,    // imminent (1 turn before)
  critical,  // due now or past
}

/// Type of alert.
enum AlertType {
  mission,
  loan,
  price,
  crew,
  encounter,
  system,
}

/// A smart alert shown in the alert bell.
class Alert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? actionRoute;
  final int turn;
  final bool dismissed;

  const Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.actionRoute,
    required this.turn,
    this.dismissed = false,
  });

  Alert copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    String? actionRoute,
    int? turn,
    bool? dismissed,
  }) {
    return Alert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      actionRoute: actionRoute ?? this.actionRoute,
      turn: turn ?? this.turn,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}
