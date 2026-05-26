import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Importar aqui
import 'package:frontend/theme/app_theme.dart'; // Importar aqui

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initializeSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RH Documentos',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      routerConfig: appRouter,
    );
  }
}
