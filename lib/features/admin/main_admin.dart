import 'package:flutter/material.dart';
import '../../app/constants/app_constants.dart';
import '../../app/constants/app_router.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turf Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Color(0xFF4CAF50),
        useMaterial3: true,
      ),
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppConstants.routeAdmin,
    );
  }
}