import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'injection_container.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Register SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  
  // Register Dio
  final dio = Dio();
  dio.options = BaseOptions(
    baseUrl: 'https://api.mindfence.com/', // Replace with actual API URL
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  );
  getIt.registerSingleton<Dio>(dio);
  
  // Initialize injectable dependencies
  getIt.init();
}

// Register modules
@module
abstract class RegisterModule {
  @singleton
  SharedPreferences get sharedPreferences => getIt<SharedPreferences>();
  
  @singleton
  Dio get dio => getIt<Dio>();
}