import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'injection_container.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Initialize injectable dependencies
  await getIt.init();
}

// Register modules
@module
abstract class RegisterModule {
  @singleton
  @preResolve
  Future<SharedPreferences> get sharedPreferences => SharedPreferences.getInstance();
  
  @singleton
  Dio get dio {
    final dio = Dio();
    dio.options = BaseOptions(
      baseUrl: 'https://api.mindfence.com/', // Replace with actual API URL
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    return dio;
  }
}