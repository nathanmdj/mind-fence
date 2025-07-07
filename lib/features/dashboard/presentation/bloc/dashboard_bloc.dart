import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/domain/entities/blocked_app.dart';
import '../../../../shared/domain/entities/focus_session.dart';
import '../../../../shared/domain/entities/usage_stats.dart';
import '../../../../shared/domain/repositories/blocked_apps_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final BlockedAppsRepository _blockedAppsRepository;
  
  DashboardBloc(this._blockedAppsRepository) : super(DashboardInitial()) {
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
      // Get real data from repositories
      final isBlocking = await _blockedAppsRepository.isBlocking();
      final blockedApps = await _blockedAppsRepository.getBlockedApps();
      
      final dashboardData = DashboardData(
        blockedApps: blockedApps,
        currentFocusSession: _getMockFocusSession(),
        todayStats: _getMockUsageStats(),
        isBlockingActive: isBlocking,
        totalScreenTime: 240, // 4 hours in minutes
        productivityScore: 85.0,
        streakDays: 7,
      );
      
      emit(DashboardLoaded(data: dashboardData));
    } catch (error) {
      print('Error initializing dashboard: $error');
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
        final newBlockingState = !currentState.data.isBlockingActive;
        
        if (newBlockingState) {
          // Start blocking - get blocked apps package names
          final blockedAppsPackages = currentState.data.blockedApps
              .where((app) => app.isBlocked)
              .map((app) => app.packageName)
              .toList();
          
          print('Starting blocking with apps: $blockedAppsPackages');
          await _blockedAppsRepository.startBlocking(blockedAppsPackages);
        } else {
          // Stop blocking
          print('Stopping blocking');
          await _blockedAppsRepository.stopBlocking();
        }
        
        final updatedData = currentState.data.copyWith(
          isBlockingActive: newBlockingState,
        );
        
        emit(DashboardLoaded(data: updatedData));
      } catch (error) {
        print('Error toggling blocking: $error');
        emit(DashboardError(message: 'Failed to toggle blocking: ${error.toString()}'));
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
        // Start blocking with focus session apps
        await _blockedAppsRepository.startBlocking(event.blockedApps);
        
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
          isBlockingActive: true,
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
        // Stop blocking when focus session ends
        await _blockedAppsRepository.stopBlocking();
        
        final updatedData = currentState.data.copyWith(
          currentFocusSession: null,
          isBlockingActive: false,
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
        packageName: 'com.zhiliaoapp.musically',
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