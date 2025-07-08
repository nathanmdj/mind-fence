import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_bloc_observer.dart';
import 'core/widgets/app_router.dart';
import 'core/services/app_lifecycle_service.dart';
import 'core/services/permission_status_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await configureDependencies();
  
  // Initialize shared preferences
  await SharedPreferences.getInstance();
  
  // Set up BLoC observer for debugging
  Bloc.observer = AppBlocObserver();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize app lifecycle service
  final lifecycleService = getIt<AppLifecycleService>();
  lifecycleService.initialize();
  
  // Initialize permission status service
  final permissionStatusService = getIt<PermissionStatusService>();
  await permissionStatusService.initialize();
  
  runApp(const MindFenceApp());
}

class MindFenceApp extends StatefulWidget {
  const MindFenceApp({super.key});

  @override
  State<MindFenceApp> createState() => _MindFenceAppState();
}

class _MindFenceAppState extends State<MindFenceApp> {
  @override
  void dispose() {
    // Clean up services
    final lifecycleService = getIt<AppLifecycleService>();
    lifecycleService.dispose();
    
    final permissionStatusService = getIt<PermissionStatusService>();
    permissionStatusService.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mind Fence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}