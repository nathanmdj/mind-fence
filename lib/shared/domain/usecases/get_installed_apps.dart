import 'package:injectable/injectable.dart';
import '../entities/blocked_app.dart';
import '../repositories/blocked_apps_repository.dart';

@injectable
class GetInstalledApps {
  final BlockedAppsRepository _repository;

  GetInstalledApps(this._repository);

  Future<List<BlockedApp>> call() async {
    return await _repository.getInstalledApps();
  }
}