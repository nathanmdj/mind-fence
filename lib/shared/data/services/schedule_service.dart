import 'dart:async';
import 'package:injectable/injectable.dart';
import '../datasources/blocked_apps_datasource.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/entities/schedule.dart';

@injectable
class ScheduleService {
  final ScheduleRepository _scheduleRepository;
  final BlockedAppsDataSource _blockedAppsDataSource;
  Timer? _schedulerTimer;
  Schedule? _currentActiveSchedule;

  ScheduleService(this._scheduleRepository, this._blockedAppsDataSource);

  void startScheduleMonitoring() {
    // Check every minute for schedule changes
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndApplySchedules();
    });
    
    // Also check immediately
    _checkAndApplySchedules();
  }

  void stopScheduleMonitoring() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
  }

  Future<void> _checkAndApplySchedules() async {
    try {
      final currentSchedule = await _scheduleRepository.getCurrentActiveSchedule();
      
      // If no schedule is active, stop blocking if it was previously active
      if (currentSchedule == null) {
        if (_currentActiveSchedule != null) {
          await _stopScheduledBlocking();
          _currentActiveSchedule = null;
        }
        return;
      }

      // If a new schedule is active or schedule has changed
      if (_currentActiveSchedule?.id != currentSchedule.id) {
        await _applySchedule(currentSchedule);
        _currentActiveSchedule = currentSchedule;
      }
    } catch (e) {
      // Handle error
      print('Error checking schedules: $e');
    }
  }

  Future<void> _applySchedule(Schedule schedule) async {
    try {
      // Combine blocked apps and websites from the schedule
      final allBlockedApps = schedule.blockedApps;

      // Start blocking for apps
      if (allBlockedApps.isNotEmpty) {
        await _blockedAppsDataSource.startBlocking(allBlockedApps);
      }

      // Start VPN for websites (if any)
      // This would require the VPN functionality to be integrated
      // For now, website blocking is handled by the VPN service separately

      print('Applied schedule: ${schedule.name}');
    } catch (e) {
      print('Error applying schedule: $e');
    }
  }

  Future<void> _stopScheduledBlocking() async {
    try {
      // Stop app blocking
      await _blockedAppsDataSource.stopBlocking();
      
      // Stop VPN blocking
      // This would stop the VPN service
      
      print('Stopped scheduled blocking');
    } catch (e) {
      print('Error stopping scheduled blocking: $e');
    }
  }

  Future<Schedule?> getCurrentActiveSchedule() async {
    return await _scheduleRepository.getCurrentActiveSchedule();
  }

  Future<bool> hasActiveSchedule() async {
    return await _scheduleRepository.hasActiveSchedule();
  }

  void dispose() {
    stopScheduleMonitoring();
  }
}