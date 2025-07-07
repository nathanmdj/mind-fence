import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../shared/domain/entities/blocked_app.dart';
import '../../../../shared/domain/entities/focus_session.dart';
import '../../../../shared/domain/entities/usage_stats.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardInitialized>(_onDashboardInitialized);
    on<DashboardRefreshed>(_onDashboardRefreshed);
    on<BlockingStatusToggled>(_onBlockingStatusToggled);
    on<FocusSessionStarted>(_onFocusSessionStarted);
    on<FocusSessionStopped>(_onFocusSessionStopped);
  }

  void _onDashboardInitialized(
    DashboardInitialized event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    
    try {
      // Simulate loading data
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data - replace with real data from repositories
      final mockData = DashboardData(
        blockedApps: _getMockBlockedApps(),
        currentFocusSession: _getMockFocusSession(),
        todayStats: _getMockUsageStats(),
        isBlockingActive: true,
        totalScreenTime: 240, // 4 hours in minutes
        productivityScore: 85.0,
        streakDays: 7,
      );
      
      emit(DashboardLoaded(data: mockData));
    } catch (error) {
      emit(DashboardError(message: error.toString()));
    }
  }

  void _onDashboardRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) {
    add(const DashboardInitialized());
  }

  void _onBlockingStatusToggled(
    BlockingStatusToggled event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      try {
        // Simulate blocking toggle
        await Future.delayed(const Duration(milliseconds: 500));
        
        final updatedData = currentState.data.copyWith(
          isBlockingActive: !currentState.data.isBlockingActive,
        );
        
        emit(DashboardLoaded(data: updatedData));
      } catch (error) {
        emit(DashboardError(message: error.toString()));
      }
    }
  }

  void _onFocusSessionStarted(
    FocusSessionStarted event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      try {
        // Simulate starting focus session
        await Future.delayed(const Duration(milliseconds: 500));
        
        final newFocusSession = FocusSession(
          id: 'focus_${DateTime.now().millisecondsSinceEpoch}',
          name: event.sessionName,
          duration: event.duration,
          startTime: DateTime.now(),
          status: FocusSessionStatus.active,
          blockedApps: event.blockedApps,
        );
        
        final updatedData = currentState.data.copyWith(
          currentFocusSession: newFocusSession,
        );
        
        emit(DashboardLoaded(data: updatedData));
      } catch (error) {
        emit(DashboardError(message: error.toString()));
      }
    }
  }

  void _onFocusSessionStopped(
    FocusSessionStopped event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      
      try {
        // Simulate stopping focus session
        await Future.delayed(const Duration(milliseconds: 500));
        
        final updatedData = currentState.data.copyWith(
          currentFocusSession: null,
        );
        
        emit(DashboardLoaded(data: updatedData));
      } catch (error) {
        emit(DashboardError(message: error.toString()));
      }
    }
  }

  List<BlockedApp> _getMockBlockedApps() {
    return [
      const BlockedApp(
        id: '1',
        name: 'Instagram',
        packageName: 'com.instagram.android',
        iconPath: 'assets/icons/instagram.png',
        isBlocked: true,
        categories: ['Social Media'],
      ),
      const BlockedApp(
        id: '2',
        name: 'TikTok',
        packageName: 'com.tiktok.android',
        iconPath: 'assets/icons/tiktok.png',
        isBlocked: true,
        categories: ['Social Media'],
      ),
      const BlockedApp(
        id: '3',
        name: 'Twitter',
        packageName: 'com.twitter.android',
        iconPath: 'assets/icons/twitter.png',
        isBlocked: false,
        categories: ['Social Media'],
      ),
    ];
  }

  FocusSession? _getMockFocusSession() {
    return null; // No active session initially
  }

  List<UsageStats> _getMockUsageStats() {
    return [
      UsageStats(
        id: '1',
        appPackageName: 'com.instagram.android',
        appName: 'Instagram',
        date: DateTime.now(),
        totalTimeInMillis: 120000, // 2 minutes
        launchCount: 5,
        firstTimeStamp: DateTime.now().subtract(const Duration(hours: 8)),
        lastTimeStamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      UsageStats(
        id: '2',
        appPackageName: 'com.tiktok.android',
        appName: 'TikTok',
        date: DateTime.now(),
        totalTimeInMillis: 180000, // 3 minutes
        launchCount: 3,
        firstTimeStamp: DateTime.now().subtract(const Duration(hours: 6)),
        lastTimeStamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }
}

class DashboardData extends Equatable {
  final List<BlockedApp> blockedApps;
  final FocusSession? currentFocusSession;
  final List<UsageStats> todayStats;
  final bool isBlockingActive;
  final int totalScreenTime; // in minutes
  final double productivityScore;
  final int streakDays;

  const DashboardData({
    required this.blockedApps,
    this.currentFocusSession,
    required this.todayStats,
    required this.isBlockingActive,
    required this.totalScreenTime,
    required this.productivityScore,
    required this.streakDays,
  });

  DashboardData copyWith({
    List<BlockedApp>? blockedApps,
    FocusSession? currentFocusSession,
    List<UsageStats>? todayStats,
    bool? isBlockingActive,
    int? totalScreenTime,
    double? productivityScore,
    int? streakDays,
  }) {
    return DashboardData(
      blockedApps: blockedApps ?? this.blockedApps,
      currentFocusSession: currentFocusSession ?? this.currentFocusSession,
      todayStats: todayStats ?? this.todayStats,
      isBlockingActive: isBlockingActive ?? this.isBlockingActive,
      totalScreenTime: totalScreenTime ?? this.totalScreenTime,
      productivityScore: productivityScore ?? this.productivityScore,
      streakDays: streakDays ?? this.streakDays,
    );
  }

  @override
  List<Object?> get props => [
    blockedApps,
    currentFocusSession,
    todayStats,
    isBlockingActive,
    totalScreenTime,
    productivityScore,
    streakDays,
  ];
}