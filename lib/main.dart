import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/constants/app_constants.dart';
import 'app/constants/app_router.dart';
import 'app/theme/app_theme.dart';

import 'features/auth/providers/auth_notifier.dart';
import 'features/auth/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );

  // UI configs
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: CourtlyApp()));
}

class CourtlyApp extends ConsumerWidget {
  const CourtlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);

    return MaterialApp(
      title: 'Courtly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      home: authAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => Scaffold(body: Center(child: Text(err.toString()))),
        data: (authState) {
          if (authState.user == null) {
            return const LoginScreen();
          }

          return Navigator(
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppConstants.routeHome,
          );
        },
      ),
    );
  }
}
