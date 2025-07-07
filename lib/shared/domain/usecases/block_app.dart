import 'package:injectable/injectable.dart';
import '../repositories/blocked_apps_repository.dart';

@injectable
class BlockApp {
  final BlockedAppsRepository _repository;

  BlockApp(this._repository);

  Future<void> call(String packageName) async {
    await _repository.blockApp(packageName);
  }
}