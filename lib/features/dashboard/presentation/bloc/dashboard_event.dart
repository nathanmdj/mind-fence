part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object> get props => [];
}

class DashboardInitialized extends DashboardEvent {
  const DashboardInitialized();
}

class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed();
}

class BlockingStatusToggled extends DashboardEvent {
  const BlockingStatusToggled();
}

class FocusSessionStarted extends DashboardEvent {
  final String sessionName;
  final int duration; // in minutes
  final List<String> blockedApps;

  const FocusSessionStarted({
    required this.sessionName,
    required this.duration,
    required this.blockedApps,
  });

  @override
  List<Object> get props => [sessionName, duration, blockedApps];
}

class FocusSessionStopped extends DashboardEvent {
  const FocusSessionStopped();
}