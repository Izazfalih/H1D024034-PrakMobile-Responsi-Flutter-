import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'services/local_storage_service.dart';
import 'services/weather_api_service.dart';
import 'viewmodels/location_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';
import 'views/screens/main_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await LocalStorageService.init();
  final apiService = WeatherApiService();

  runApp(
    SkyCastApp(
      apiService: apiService,
      storageService: storageService,
    ),
  );
}

/// Root widget aplikasi SkyCast yang mengikat MultiProvider MVVM dan Theme Material 3.
class SkyCastApp extends StatelessWidget {
  const SkyCastApp({
    super.key,
    required this.apiService,
    required this.storageService,
    this.autoInitialize = true,
  });

  final WeatherApiService apiService;
  final LocalStorageService storageService;
  final bool autoInitialize;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final vm = WeatherViewModel(
              apiService: apiService,
              storageService: storageService,
            );
            if (autoInitialize) {
              vm.initialize();
            }
            return vm;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final vm = LocationViewModel(
              apiService: apiService,
              storageService: storageService,
            );
            vm.loadSavedData();
            return vm;
          },
        ),
      ],
      child: Consumer<WeatherViewModel>(
        builder: (context, weatherVm, _) {
          return MaterialApp(
            title: 'SkyCast',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: weatherVm.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainShellScreen(),
          );
        },
      ),
    );
  }
}
