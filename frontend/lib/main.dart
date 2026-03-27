import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Importar aqui
import 'package:frontend/theme/app_theme.dart'; // Importar aqui

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: ApiService.initializeSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Enquanto a sessao esta sendo inicializada, mostra um splash screen simples
          return MaterialApp(
            title: 'RH Documentos',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false, // Manter aqui
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
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
      },
    );
  }
}
