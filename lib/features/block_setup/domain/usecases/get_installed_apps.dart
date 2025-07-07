import 'package:injectable/injectable.dart';
import '../../../../shared/domain/entities/blocked_app.dart';
import '../repositories/blocking_repository.dart';

@injectable
class GetInstalledApps {
  final BlockingRepository repository;

  GetInstalledApps(this.repository);

  Future<List<BlockedApp>> call() async {
    return await repository.getInstalledApps();
  }
}