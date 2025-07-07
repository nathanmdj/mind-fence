// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter/services.dart' as _i281;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:mind_fence/core/di/injection_container.dart' as _i92;
import 'package:mind_fence/features/block_setup/data/repositories/blocking_repository_impl.dart'
    as _i647;
import 'package:mind_fence/features/block_setup/domain/repositories/blocking_repository.dart'
    as _i895;
import 'package:mind_fence/features/block_setup/domain/usecases/get_installed_apps.dart'
    as _i319;
import 'package:mind_fence/features/block_setup/domain/usecases/request_permissions.dart'
    as _i967;
import 'package:mind_fence/features/block_setup/domain/usecases/toggle_app_blocking.dart'
    as _i904;
import 'package:mind_fence/features/block_setup/presentation/bloc/block_setup_bloc.dart'
    as _i161;
import 'package:mind_fence/features/dashboard/presentation/bloc/dashboard_bloc.dart'
    as _i732;
import 'package:mind_fence/shared/data/datasources/blocked_apps_datasource.dart'
    as _i542;
import 'package:mind_fence/shared/data/datasources/emergency_override_datasource.dart'
    as _i754;
import 'package:mind_fence/shared/data/datasources/schedule_datasource.dart'
    as _i134;
import 'package:mind_fence/shared/data/repositories/blocked_apps_repository_impl.dart'
    as _i599;
import 'package:mind_fence/shared/data/repositories/emergency_override_repository_impl.dart'
    as _i702;
import 'package:mind_fence/shared/data/repositories/schedule_repository_impl.dart'
    as _i348;
import 'package:mind_fence/shared/data/services/database_service.dart' as _i294;
import 'package:mind_fence/shared/data/services/emergency_override_service.dart'
    as _i216;
import 'package:mind_fence/shared/data/services/platform_service.dart' as _i178;
import 'package:mind_fence/shared/data/services/preferences_service.dart'
    as _i1052;
import 'package:mind_fence/shared/data/services/schedule_service.dart' as _i339;
import 'package:mind_fence/shared/domain/repositories/blocked_apps_repository.dart'
    as _i41;
import 'package:mind_fence/shared/domain/repositories/emergency_override_repository.dart'
    as _i601;
import 'package:mind_fence/shared/domain/repositories/schedule_repository.dart'
    as _i470;
import 'package:mind_fence/shared/domain/usecases/activate_emergency_override.dart'
    as _i851;
import 'package:mind_fence/shared/domain/usecases/block_app.dart' as _i164;
import 'package:mind_fence/shared/domain/usecases/create_schedule.dart'
    as _i493;
import 'package:mind_fence/shared/domain/usecases/get_current_active_schedule.dart'
    as _i334;
import 'package:mind_fence/shared/domain/usecases/get_installed_apps.dart'
    as _i829;
import 'package:mind_fence/shared/domain/usecases/request_emergency_override.dart'
    as _i976;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    gh.factory<_i178.PlatformService>(() => _i178.PlatformService());
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.singleton<_i361.Dio>(() => registerModule.dio);
    gh.singleton<_i281.MethodChannel>(
        () => registerModule.deviceControlChannel);
    gh.singleton<_i294.DatabaseService>(() => _i294.DatabaseService());
    gh.factory<_i542.BlockedAppsDataSource>(
        () => _i542.BlockedAppsDataSourceImpl(
              gh<_i178.PlatformService>(),
              gh<_i294.DatabaseService>(),
            ));
    gh.factory<_i895.BlockingRepository>(() => _i647.BlockingRepositoryImpl(
          gh<_i281.MethodChannel>(),
          gh<_i460.SharedPreferences>(),
          gh<_i178.PlatformService>(),
        ));
    gh.factory<_i1052.PreferencesService>(
        () => _i1052.PreferencesService(gh<_i294.DatabaseService>()));
    gh.factory<_i754.EmergencyOverrideDataSource>(() =>
        _i754.EmergencyOverrideDataSourceImpl(gh<_i294.DatabaseService>()));
    gh.factory<_i134.ScheduleDataSource>(
        () => _i134.ScheduleDataSourceImpl(gh<_i294.DatabaseService>()));
    gh.factory<_i470.ScheduleRepository>(
        () => _i348.ScheduleRepositoryImpl(gh<_i134.ScheduleDataSource>()));
    gh.factory<_i904.ToggleAppBlocking>(
        () => _i904.ToggleAppBlocking(gh<_i895.BlockingRepository>()));
    gh.factory<_i967.RequestPermissions>(
        () => _i967.RequestPermissions(gh<_i895.BlockingRepository>()));
    gh.factory<_i319.GetInstalledApps>(
        () => _i319.GetInstalledApps(gh<_i895.BlockingRepository>()));
    gh.factory<_i41.BlockedAppsRepository>(() =>
        _i599.BlockedAppsRepositoryImpl(gh<_i542.BlockedAppsDataSource>()));
    gh.factory<_i161.BlockSetupBloc>(() => _i161.BlockSetupBloc(
          gh<_i319.GetInstalledApps>(),
          gh<_i904.ToggleAppBlocking>(),
          gh<_i967.RequestPermissions>(),
          gh<_i895.BlockingRepository>(),
        ));
    gh.factory<_i334.GetCurrentActiveSchedule>(
        () => _i334.GetCurrentActiveSchedule(gh<_i470.ScheduleRepository>()));
    gh.factory<_i493.CreateSchedule>(
        () => _i493.CreateSchedule(gh<_i470.ScheduleRepository>()));
    gh.factory<_i164.BlockApp>(
        () => _i164.BlockApp(gh<_i41.BlockedAppsRepository>()));
    gh.factory<_i829.GetInstalledApps>(
        () => _i829.GetInstalledApps(gh<_i41.BlockedAppsRepository>()));
    gh.factory<_i601.EmergencyOverrideRepository>(() =>
        _i702.EmergencyOverrideRepositoryImpl(
            gh<_i754.EmergencyOverrideDataSource>()));
    gh.factory<_i339.ScheduleService>(() => _i339.ScheduleService(
          gh<_i470.ScheduleRepository>(),
          gh<_i542.BlockedAppsDataSource>(),
        ));
    gh.factory<_i851.ActivateEmergencyOverride>(() =>
        _i851.ActivateEmergencyOverride(
            gh<_i601.EmergencyOverrideRepository>()));
    gh.factory<_i976.RequestEmergencyOverride>(() =>
        _i976.RequestEmergencyOverride(
            gh<_i601.EmergencyOverrideRepository>()));
    gh.factory<_i732.DashboardBloc>(
        () => _i732.DashboardBloc(gh<_i41.BlockedAppsRepository>()));
    gh.factory<_i216.EmergencyOverrideService>(
        () => _i216.EmergencyOverrideService(
              gh<_i601.EmergencyOverrideRepository>(),
              gh<_i542.BlockedAppsDataSource>(),
            ));
    return this;
  }
}

class _$RegisterModule extends _i92.RegisterModule {}
