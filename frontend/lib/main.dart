import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/nlp_repository.dart';
import 'data/repositories/prediction_repository.dart';
import 'data/services/api_service.dart';
import 'features/dashboard/view_models/dashboard_view_model.dart';
import 'features/mlops/view_models/mlops_view_model.dart';
import 'features/nlp_assistant/view_models/nlp_view_model.dart';
import 'features/prediction/view_models/prediction_view_model.dart';
import 'shared/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive
  await Hive.initFlutter();

  // Build services and repositories
  final apiService = ApiService();
  final nlpRepository = NlpRepository(apiService: apiService);
  await nlpRepository.init();

  runApp(
    MultiProvider(
      providers: [
        // Data layer (singletons)
        Provider<ApiService>.value(value: apiService),
        Provider<PredictionRepository>(
          create: (_) => PredictionRepository(apiService: apiService),
        ),
        Provider<DashboardRepository>(
          create: (_) => const DashboardRepository(),
        ),
        Provider<NlpRepository>.value(value: nlpRepository),

        // ViewModels (created fresh, own their lifecycles)
        ChangeNotifierProvider(
          create: (ctx) => DashboardViewModel(
            repository: ctx.read<DashboardRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PredictionViewModel(
            repository: ctx.read<PredictionRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => NlpViewModel(
            repository: ctx.read<NlpRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MlopsViewModel(),
        ),
      ],
      child: const EcoSmartApp(),
    ),
  );
}

class EcoSmartApp extends StatelessWidget {
  const EcoSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EcoSmart Classifier',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
