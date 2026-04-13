import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/constants/app_constants.dart';
import 'app/constants/app_router.dart';
import 'app/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const CourtlyApp());
}

class CourtlyApp extends StatelessWidget {
  const CourtlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Courtly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppConstants.routeSplash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
