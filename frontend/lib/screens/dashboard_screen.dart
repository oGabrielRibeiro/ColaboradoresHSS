import 'package:flutter/material.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/dashboard_resumo_model.dart';
import 'package:frontend/widgets/dashboard_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardResumo? _resumo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resumo = await ApiService.getDashboardResumo();
      setState(() {
        _resumo = resumo;
        _isLoading = false;
      });

      // Verifica se há alertas para mostrar no popup
      _mostrarPopupSeNecessario(resumo);
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  void _mostrarPopupSeNecessario(DashboardResumo resumo) {
    if (resumo.documentosVencidos > 0 || resumo.documentosAVencer > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarPopupAlerta(resumo);
      });
    }
  }

  void _mostrarPopupAlerta(DashboardResumo resumo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Atenção!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resumo.documentosVencidos > 0)
              Text(
                '🔴 ${resumo.documentosVencidos} documento(s) VENCIDO(S)',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            if (resumo.documentosAVencer > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '🟡 ${resumo.documentosAVencer} documento(s) a vencer nos próximos 30 dias',
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navegar para a lista de documentos vencidos
            },
            child: const Text('Ver vencidos'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarDados,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregarDados,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cards principais
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: [
                            DashboardCard(
                              title: 'Colaboradores',
                              value: _resumo?.totalColaboradores.toString() ?? '0',
                              icon: Icons.people,
                              color: AppTheme.primaryGreen,
                              onTap: () {
                                // TODO: Navegar para lista de colaboradores
                              },
                            ),
                            DashboardCard(
                              title: 'Empresas',
                              value: _resumo?.totalEmpresas.toString() ?? '0',
                              icon: Icons.business,
                              color: AppTheme.primaryBlue,
                              onTap: () {
                                // TODO: Navegar para lista de empresas
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Documentos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                          children: [
                            DashboardCard(
                              title: 'Vencidos',
                              value: _resumo?.documentosVencidos.toString() ?? '0',
                              icon: Icons.warning,
                              color: Colors.red,
                              onTap: () {
                                // TODO: Filtrar vencidos
                              },
                            ),
                            DashboardCard(
                              title: 'A vencer',
                              value: _resumo?.documentosAVencer.toString() ?? '0',
                              icon: Icons.schedule,
                              color: Colors.orange,
                              onTap: () {
                                // TODO: Filtrar a vencer
                              },
                            ),
                            DashboardCard(
                              title: 'OK',
                              value: _resumo?.documentosOK.toString() ?? '0',
                              icon: Icons.check_circle,
                              color: Colors.green,
                              onTap: () {
                                // TODO: Filtrar ok
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Adicionar novo colaborador
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}