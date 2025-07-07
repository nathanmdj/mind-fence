import '../entities/focus_session.dart';

abstract class FocusSessionsRepository {
  Future<List<FocusSession>> getFocusSessions();
  Future<FocusSession?> getCurrentFocusSession();
  Future<FocusSession> getFocusSession(String id);
  Future<void> createFocusSession(FocusSession session);
  Future<void> updateFocusSession(FocusSession session);
  Future<void> deleteFocusSession(String id);
  Future<void> startFocusSession(String id);
  Future<void> pauseFocusSession(String id);
  Future<void> resumeFocusSession(String id);
  Future<void> completeFocusSession(String id);
  Future<void> cancelFocusSession(String id);
  Future<List<FocusSession>> getFocusSessionHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  Stream<FocusSession?> watchCurrentFocusSession();
}