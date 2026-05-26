import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/screens/colaborador_detail_screen.dart'; // OBS: Assumindo que este é o arquivo e nome da tela de detalhes
import 'package:frontend/screens/empresa_detail_screen.dart'; // Assumindo que este é o arquivo e nome da tela de detalhes da empresa
import 'package:frontend/screens/colaboradores_list_screen.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/documentos_status_screen.dart';
import 'package:frontend/screens/documento_create_screen.dart';
import 'package:frontend/screens/empresas_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/tipos_documento_screen.dart';
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
          }, // Rota para /dashboard/empresas
          routes: <RouteBase>[
            GoRoute(
              path: ':id', // Rota para /dashboard/empresas/:id
              builder: (BuildContext context, GoRouterState state) {
                final id = int.parse(state.pathParameters['id']!);
                return EmpresaDetailScreen(empresaId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'colaboradores',
          builder: (BuildContext context, GoRouterState state) {
            return const ColaboradoresListScreen();
          }, // Rota para /dashboard/colaboradores
          routes: <RouteBase>[
            GoRoute(
              path: ':id', // Rota para /dashboard/colaboradores/:id
              builder: (BuildContext context, GoRouterState state) {
                final id = int.parse(state.pathParameters['id']!);
                return ColaboradorDetailScreen(colaboradorId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'documentos/novo',
          builder: (BuildContext context, GoRouterState state) {
            final colaboradorIdParam =
                state.uri.queryParameters['colaborador_id'];
            final colaboradorId = int.tryParse(colaboradorIdParam ?? '');
            return DocumentoCreateScreen(colaboradorIdInicial: colaboradorId);
          },
        ),
        GoRoute(
          path: 'tipos-documento',
          builder: (BuildContext context, GoRouterState state) {
            return const TiposDocumentoScreen();
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
