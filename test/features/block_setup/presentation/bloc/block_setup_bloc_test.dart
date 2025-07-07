import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mind_fence/features/block_setup/presentation/bloc/block_setup_bloc.dart';
import 'package:mind_fence/features/block_setup/presentation/bloc/block_setup_event.dart';
import 'package:mind_fence/features/block_setup/presentation/bloc/block_setup_state.dart';
import 'package:mind_fence/features/block_setup/domain/usecases/get_installed_apps.dart';
import 'package:mind_fence/features/block_setup/domain/usecases/toggle_app_blocking.dart';
import 'package:mind_fence/features/block_setup/domain/usecases/request_permissions.dart';
import 'package:mind_fence/features/block_setup/domain/repositories/blocking_repository.dart';
import 'package:mind_fence/shared/domain/entities/blocked_app.dart';

class MockGetInstalledApps extends Mock implements GetInstalledApps {}
class MockToggleAppBlocking extends Mock implements ToggleAppBlocking {}
class MockRequestPermissions extends Mock implements RequestPermissions {}
class MockBlockingRepository extends Mock implements BlockingRepository {}

void main() {
  late BlockSetupBloc bloc;
  late MockGetInstalledApps mockGetInstalledApps;
  late MockToggleAppBlocking mockToggleAppBlocking;
  late MockRequestPermissions mockRequestPermissions;
  late MockBlockingRepository mockRepository;

  const testApp = BlockedApp(
    id: 'test_id',
    name: 'Test App',
    packageName: 'com.test.app',
    iconPath: '',
    isBlocked: false,
  );

  const blockedApp = BlockedApp(
    id: 'blocked_id',
    name: 'Blocked App',
    packageName: 'com.blocked.app',
    iconPath: '',
    isBlocked: true,
  );

  setUp(() {
    mockGetInstalledApps = MockGetInstalledApps();
    mockToggleAppBlocking = MockToggleAppBlocking();
    mockRequestPermissions = MockRequestPermissions();
    mockRepository = MockBlockingRepository();

    bloc = BlockSetupBloc(
      mockGetInstalledApps,
      mockToggleAppBlocking,
      mockRequestPermissions,
      mockRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('BlockSetupBloc', () {
    test('initial state is BlockSetupInitial', () {
      expect(bloc.state, equals(BlockSetupInitial()));
    });

    blocTest<BlockSetupBloc, BlockSetupState>(
      'emits loading then loaded when LoadInstalledApps is added',
      build: () {
        when(() => mockGetInstalledApps.call()).thenAnswer((_) async => [testApp]);
        when(() => mockRepository.getBlockedApps()).thenAnswer((_) async => [blockedApp]);
        when(() => mockRequestPermissions.hasUsageStatsPermission()).thenAnswer((_) async => true);
        when(() => mockRequestPermissions.hasOverlayPermission()).thenAnswer((_) async => true);
        when(() => mockRepository.isBlocking()).thenAnswer((_) async => false);
        return bloc;
      },
      act: (bloc) => bloc.add(LoadInstalledApps()),
      expect: () => [
        BlockSetupLoading(),
        isA<BlockSetupLoaded>()
            .having((state) => state.installedApps.length, 'installed apps count', 1)
            .having((state) => state.blockedApps.length, 'blocked apps count', 1)
            .having((state) => state.hasUsageStatsPermission, 'usage stats permission', true)
            .having((state) => state.hasOverlayPermission, 'overlay permission', true)
            .having((state) => state.isBlocking, 'is blocking', false),
      ],
    );

    blocTest<BlockSetupBloc, BlockSetupState>(
      'emits error when LoadInstalledApps fails',
      build: () {
        when(() => mockGetInstalledApps.call()).thenThrow(Exception('Failed to get apps'));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadInstalledApps()),
      expect: () => [
        BlockSetupLoading(),
        isA<BlockSetupError>()
            .having((state) => state.message, 'error message', contains('Failed to get apps')),
      ],
    );

    blocTest<BlockSetupBloc, BlockSetupState>(
      'toggles app blocking when ToggleAppBlocking is added',
      build: () {
        when(() => mockToggleAppBlocking.call(any(), any())).thenAnswer((_) async {});
        when(() => mockRepository.getBlockedApps()).thenAnswer((_) async => [testApp.copyWith(isBlocked: true)]);
        return bloc;
      },
      seed: () => const BlockSetupLoaded(
        installedApps: [testApp],
        blockedApps: [],
        filteredApps: [testApp],
        hasUsageStatsPermission: true,
        hasOverlayPermission: true,
        isBlocking: false,
      ),
      act: (bloc) => bloc.add(ToggleAppBlocking(testApp, true)),
      expect: () => [
        isA<BlockSetupLoaded>()
            .having((state) => state.installedApps.first.isBlocked, 'app is blocked', true)
            .having((state) => state.blockedApps.length, 'blocked apps count', 1),
      ],
      verify: (_) {
        verify(() => mockToggleAppBlocking.call(testApp, true)).called(1);
      },
    );

    blocTest<BlockSetupBloc, BlockSetupState>(
      'filters apps when FilterApps is added',
      build: () => bloc,
      seed: () => const BlockSetupLoaded(
        installedApps: [testApp, blockedApp],
        blockedApps: [blockedApp],
        filteredApps: [testApp, blockedApp],
        hasUsageStatsPermission: true,
        hasOverlayPermission: true,
        isBlocking: false,
      ),
      act: (bloc) => bloc.add(const FilterApps('Test')),
      expect: () => [
        isA<BlockSetupLoaded>()
            .having((state) => state.filteredApps.length, 'filtered apps count', 1)
            .having((state) => state.filteredApps.first.name, 'filtered app name', 'Test App')
            .having((state) => state.searchQuery, 'search query', 'Test'),
      ],
    );

    blocTest<BlockSetupBloc, BlockSetupState>(
      'starts blocking when StartBlocking is added',
      build: () {
        when(() => mockRepository.startBlocking(any())).thenAnswer((_) async {});
        return bloc;
      },
      seed: () => const BlockSetupLoaded(
        installedApps: [testApp],
        blockedApps: [blockedApp],
        filteredApps: [testApp],
        hasUsageStatsPermission: true,
        hasOverlayPermission: true,
        isBlocking: false,
      ),
      act: (bloc) => bloc.add(StartBlocking()),
      expect: () => [
        isA<BlockSetupLoaded>()
            .having((state) => state.isBlocking, 'is blocking', true),
      ],
      verify: (_) {
        verify(() => mockRepository.startBlocking(['com.blocked.app'])).called(1);
      },
    );

    blocTest<BlockSetupBloc, BlockSetupState>(
      'stops blocking when StopBlocking is added',
      build: () {
        when(() => mockRepository.stopBlocking()).thenAnswer((_) async {});
        return bloc;
      },
      seed: () => const BlockSetupLoaded(
        installedApps: [testApp],
        blockedApps: [blockedApp],
        filteredApps: [testApp],
        hasUsageStatsPermission: true,
        hasOverlayPermission: true,
        isBlocking: true,
      ),
      act: (bloc) => bloc.add(StopBlocking()),
      expect: () => [
        isA<BlockSetupLoaded>()
            .having((state) => state.isBlocking, 'is blocking', false),
      ],
      verify: (_) {
        verify(() => mockRepository.stopBlocking()).called(1);
      },
    );
  });
}