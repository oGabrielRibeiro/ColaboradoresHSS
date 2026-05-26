import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:frontend/models/dashboard_resumo_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/widgets/dashboard_card.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardResumo? _resumo;
  bool _isLoading = true;
  String? _error;
  bool _alertaExibido = false;

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
      _mostrarPopupSeNecessario(resumo);
    } catch (e) {
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      if (mensagem.toLowerCase().contains('token') ||
          mensagem.toLowerCase().contains('sessao') ||
          mensagem.toLowerCase().contains('nao autorizado')) {
        await ApiService.logout(); // Limpa o token localmente
        if (mounted) {
          context.go('/login'); // Redireciona para o login usando GoRouter
        }
        return;
      }

      setState(() {
        _error = mensagem;
        _isLoading = false;
      });
    }
  }

  void _mostrarPopupSeNecessario(DashboardResumo resumo) {
    if (_alertaExibido) {
      return;
    }

    if (resumo.documentosVencidos > 0 || resumo.documentosAVencer > 0) {
      _alertaExibido = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mostrarPopupAlerta(resumo);
        }
      });
    }
  }

  void _mostrarPopupAlerta(DashboardResumo resumo) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atencao nos vencimentos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${resumo.documentosVencidos} documento(s) vencido(s)',
              style: const TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${resumo.documentosAVencer} documento(s) a vencer em 30 dias',
              style: const TextStyle(
                color: AppTheme.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final quickActionsColumns = width > 1200
        ? 4
        : width > 950
        ? 2
        : 1;
    final cardsCrossAxisCount = width > 1100
        ? 4
        : width > 700
        ? 2
        : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel RH HSS'),
        actions: [
          IconButton(
            onPressed: _carregarDados,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () async {
              await ApiService.logout();
              if (!context.mounted) {
                return;
              }
              context.go('/login'); // Redireciona para o login usando GoRouter
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _carregarDados,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDCF2EA), Color(0xFFE6ECFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RH HSS App 1.0',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Acompanhe o volume de colaboradores, empresas e documentos com foco em vencimentos e consistencia operacional.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Acoes rapidas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: quickActionsColumns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: quickActionsColumns == 2 ? 2.8 : 3.5,
                    children: [
                      _buildQuickAction(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Gerenciar colaboradores',
                        subtitle:
                            'Cadastre, edite e vincule colaboradores a empresas',
                        onTap: () {
                          context.push('/dashboard/colaboradores');
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.domain_add_rounded,
                        title: 'Gerenciar empresas',
                        subtitle: 'Mantenha a base de empresas e contatos',
                        onTap: () {
                          context.push('/dashboard/empresas');
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.upload_file_rounded,
                        title: 'Cadastrar documento',
                        subtitle: 'Envie documentos pessoais e empresariais',
                        onTap: () {
                          context.push('/dashboard/documentos/novo');
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.category_rounded,
                        title: 'Tipos de documento',
                        subtitle: 'Cadastre e mantenha os tipos do sistema',
                        onTap: () {
                          context.push('/dashboard/tipos-documento');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cardsCrossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: width > 700 ? 1.45 : 1.25,
                    children: [
                      DashboardCard(
                        title: 'Colaboradores',
                        subtitle: 'Cadastros ativos no sistema',
                        value: '${_resumo?.totalColaboradores ?? 0}',
                        icon: Icons.groups_2_rounded,
                        color: AppTheme.primaryGreen,
                        onTap: () {
                          context.push('/dashboard/colaboradores');
                        },
                      ),
                      DashboardCard(
                        title: 'Empresas',
                        subtitle: 'Base usada nos vinculos',
                        value: '${_resumo?.totalEmpresas ?? 0}',
                        icon: Icons.apartment_rounded,
                        color: AppTheme.primaryBlue,
                        onTap: () {
                          context.push('/dashboard/empresas');
                        },
                      ),
                      DashboardCard(
                        title: 'Vencidos',
                        subtitle: 'Exigem acao imediata',
                        value: '${_resumo?.documentosVencidos ?? 0}',
                        icon: Icons.warning_amber_rounded,
                        color: AppTheme.danger,
                        onTap: () {
                          context.push('/dashboard/documentos/vencido');
                        },
                      ),
                      DashboardCard(
                        title: 'A vencer',
                        subtitle: 'Janela de 30 dias',
                        value: '${_resumo?.documentosAVencer ?? 0}',
                        icon: Icons.schedule_rounded,
                        color: AppTheme.warning,
                        onTap: () {
                          context.push('/dashboard/documentos/a_vencer');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_resumo != null) _DocumentosStatusChart(resumo: _resumo!),
                  if (_resumo != null) const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _DocumentosStatusChart extends StatelessWidget {
  final DashboardResumo resumo;

  const _DocumentosStatusChart({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final total =
        resumo.documentosVencidos +
        resumo.documentosAVencer +
        resumo.documentosOK;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visao Geral de Documentos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      vencidos: resumo.documentosVencidos,
                      aVencer: resumo.documentosAVencer,
                      ok: resumo.documentosOK,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            total.toString(),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegend(
                        context,
                        'Em dia',
                        resumo.documentosOK,
                        AppTheme.success,
                      ),
                      const SizedBox(height: 12),
                      _buildLegend(
                        context,
                        'A vencer',
                        resumo.documentosAVencer,
                        AppTheme.warning,
                      ),
                      const SizedBox(height: 12),
                      _buildLegend(
                        context,
                        'Vencidos',
                        resumo.documentosVencidos,
                        AppTheme.danger,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    String label,
    int value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final int vencidos;
  final int aVencer;
  final int ok;

  _DonutChartPainter({
    required this.vencidos,
    required this.aVencer,
    required this.ok,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = vencidos + aVencer + ok;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    if (total == 0) {
      paint.color = Colors.grey.withValues(alpha: 0.2);
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }

    double startAngle = -math.pi / 2; // Começa a desenhar do topo

    void drawSegment(int value, Color color) {
      if (value == 0) return;
      final sweepAngle = (value / total) * 2 * math.pi;
      paint.color = color;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    // Ordem de desenho do gráfico
    drawSegment(ok, AppTheme.success);
    drawSegment(aVencer, AppTheme.warning);
    drawSegment(vencidos, AppTheme.danger);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.vencidos != vencidos ||
        oldDelegate.aVencer != aVencer ||
        oldDelegate.ok != ok;
  }
}
