import '../entities/usage_stats.dart';

abstract class UsageStatsRepository {
  Future<List<UsageStats>> getUsageStats({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? packageNames,
  });
  Future<UsageStats?> getAppUsageStats(String packageName, DateTime date);
  Future<void> recordUsageStats(UsageStats stats);
  Future<void> syncUsageStats();
  Future<Map<String, int>> getDailyScreenTime(DateTime date);
  Future<Map<String, int>> getWeeklyScreenTime(DateTime weekStart);
  Future<Map<String, int>> getMonthlyScreenTime(DateTime monthStart);
  Future<List<UsageStats>> getMostUsedApps({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  });
  Future<int> getTotalScreenTime({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<double> getProductivityScore(DateTime date);
  Future<Map<String, dynamic>> getUsageInsights({
    DateTime? startDate,
    DateTime? endDate,
  });
}