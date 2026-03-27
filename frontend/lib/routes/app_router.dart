import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/screens/colaboradores_list_screen.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/documentos_status_screen.dart';
import 'package:frontend/screens/empresas_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/api_service.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (BuildContext context, GoRouterState state) {
    final bool loggedIn = ApiService.isAuthenticated;
    final bool loggingIn = state.matchedLocation == '/login';

    // Se nao estiver logado e nao estiver na tela de login, redireciona para login
    if (!loggedIn && !loggingIn) return '/login';
    // Se estiver logado e na tela de login, redireciona para o dashboard
    if (loggedIn && loggingIn) return '/dashboard';

    // Nenhuma redirecao necessaria
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const DashboardScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'empresas',
          builder: (BuildContext context, GoRouterState state) {
            return const EmpresasScreen();
          },
        ),
        GoRoute(
          path: 'colaboradores',
          builder: (BuildContext context, GoRouterState state) {
            return const ColaboradoresListScreen();
          },
        ),
        GoRoute(
          path: 'documentos/:status', // Exemplo: /dashboard/documentos/vencidos
          builder: (BuildContext context, GoRouterState state) {
            final status = state.pathParameters['status']!;
            String title = '';
            switch (status) {
              case 'vencido':
                title = 'Documentos vencidos';
                break;
              case 'a_vencer':
                title = 'Documentos a vencer';
                break;
              default:
                title = 'Documentos';
            }
            return DocumentosStatusScreen(status: status, title: title);
          },
        ),
      ],
    ),
  ],
);
