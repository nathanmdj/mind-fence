import 'package:injectable/injectable.dart';
import '../../../../shared/domain/entities/blocked_app.dart';
import '../repositories/blocking_repository.dart';

@injectable
class ToggleAppBlocking {
  final BlockingRepository repository;

  ToggleAppBlocking(this.repository);

  Future<void> call(BlockedApp app, bool isBlocked) async {
    final updatedApp = app.copyWith(isBlocked: isBlocked);
    
    if (isBlocked) {
      await repository.addBlockedApp(updatedApp);
    } else {
      await repository.removeBlockedApp(app.packageName);
    }
    
    // Update the blocking service with current blocked apps
    final blockedApps = await repository.getBlockedApps();
    final packageNames = blockedApps.map((app) => app.packageName).toList();
    await repository.updateBlockedApps(packageNames);
  }
}