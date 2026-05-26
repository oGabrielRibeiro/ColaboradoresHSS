import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:go_router/go_router.dart';
// Importar para _ErrorState e _EmptyState
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/widgets/document_utils.dart'; // Caminho corrigido

class DocumentosStatusScreen extends StatefulWidget {
  final String status;
  final String title;

  const DocumentosStatusScreen({
    super.key,
    required this.status,
    required this.title,
  });

  @override
  State<DocumentosStatusScreen> createState() => _DocumentosStatusScreenState();
}

class _DocumentosStatusScreenState extends State<DocumentosStatusScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Documento> _documentos = [];
  bool _isGridView = false;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarDocumentos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.95 &&
        !_isLoadingMore) {
      _carregarMaisDocumentos();
    }
  }

  Future<void> _carregarDocumentos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 1;
      _documentos = [];
      _hasMore = true;
    });

    try {
      final response = await ApiService.getDocumentos(
        status: widget.status,
        page: _currentPage,
      );
      setState(() {
        _documentos = response.items;
        _hasMore = response.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _carregarMaisDocumentos() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final response = await ApiService.getDocumentos(
        status: widget.status,
        page: _currentPage,
      );
      setState(() {
        _documentos.addAll(response.items);
        _hasMore = response.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _abrirArquivo(String? arquivoPath) async {
    if (arquivoPath == null || arquivoPath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Arquivo nao disponivel')));
      return;
    }

    try {
      final signedUrl = await ApiService.getSignedFileUrl(arquivoPath);
      final url = Uri.parse(signedUrl);
      final abriu = await launchUrl(url, mode: LaunchMode.externalApplication);

      if (!abriu && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel abrir o arquivo')),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Color _statusColor(DateTime validade) {
    final hoje = DateTime.now();
    final dias = validade.difference(hoje).inDays;

    if (validade.isBefore(hoje)) {
      return AppTheme.danger;
    }
    if (dias <= 30) {
      return AppTheme.warning;
    }
    return AppTheme.success;
  }

  String _statusLabel(DateTime validade) {
    final hoje = DateTime.now();
    final dias = validade.difference(hoje).inDays;

    if (validade.isBefore(hoje)) {
      return 'Vencido';
    }
    if (dias <= 30) {
      return 'A vencer';
    }
    return 'Em dia';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDocumentos,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acompanhe os documentos filtrados por status para agir rapido sobre vencimentos e pendencias.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.push('/dashboard'),
                        icon: const Icon(Icons.dashboard_outlined),
                        label: const Text('Voltar ao painel'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/dashboard/documentos/novo'),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Novo documento'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              _isGridView
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                2, // Ajustar conforme a largura da tela
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio:
                                1.0, // Ajustar conforme o conteudo
                          ),
                      itemCount: 4, // Mostra 4 esqueletos no grid
                      itemBuilder: (context, index) =>
                          const _DocumentoSkeletonCard(),
                    )
                  : Column(
                      children: List.generate(
                        4,
                        (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _DocumentoSkeletonCard(),
                        ),
                      ),
                    )
            else if (_errorMessage.isNotEmpty &&
                _documentos.isEmpty) // Estado de erro
              _ErrorState(message: _errorMessage, onRetry: _carregarDocumentos)
            else if (_documentos.isEmpty) // Estado vazio
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Nenhum documento encontrado para este filtro'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/dashboard/documentos/novo'),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Cadastrar documento'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isGridView) // Visualizacao em Grid (usar GridView.builder diretamente)
              GridView.builder(
                // Usar GridView.builder diretamente
                key: const PageStorageKey('documentosGridView'),
                shrinkWrap:
                    true, // Permite que o GridView se ajuste ao conteudo
                physics:
                    const NeverScrollableScrollPhysics(), // Desabilita o scroll do GridView interno
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Ajustar conforme a largura da tela
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0, // Ajustar conforme o conteudo
                ),
                itemCount:
                    _documentos.length +
                    (_isLoadingMore
                        ? 1
                        : 0), // Adiciona 1 para o indicador de carregamento
                itemBuilder: (context, index) {
                  if (index == _documentos.length) {
                    return _buildLoadingMoreIndicator(); // Indicador de carregamento no final
                  }
                  return _DocumentoGridCard(
                    documento: _documentos[index],
                    onOpen: _abrirArquivo,
                  );
                },
              )
            else // Visualizacao em Lista (usar ListView.builder diretamente)
              ListView.builder(
                // Usar ListView.builder diretamente
                key: const PageStorageKey('documentosListView'),
                shrinkWrap:
                    true, // Permite que o ListView se ajuste ao conteudo
                physics:
                    const NeverScrollableScrollPhysics(), // Desabilita o scroll do ListView interno
                itemCount: _documentos.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _documentos.length) {
                    return _buildLoadingMoreIndicator();
                  }
                  final documento = _documentos[index];
                  final statusColor = _statusColor(documento.dataValidade);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  DocumentUtils.getIconForFileName(
                                    documento.arquivoNome ?? '',
                                  ),
                                  color: statusColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    documento.tipoDocumentoNome ?? 'Documento',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Chip(
                                  label: Text(
                                    _statusLabel(documento.dataValidade),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  backgroundColor: statusColor,
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              documento.colaboradorNome ??
                                  'Colaborador nao identificado',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (documento.empresaNome != null)
                              Text(
                                'Empresa: ${documento.empresaNome}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            Text(
                              'Validade: ${DateFormat('dd/MM/yyyy').format(documento.dataValidade)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Versao ${documento.versao}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (documento.arquivoPath != null)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _abrirArquivo(documento.arquivoPath),
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Abrir anexo'),
                                  ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => context.push(
                                    '/dashboard/colaboradores/${documento.colaboradorId}',
                                  ),
                                  icon: const Icon(Icons.link_rounded),
                                  label: const Text('Ver vínculo'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// Reutilizando _ErrorState e _EmptyState de empresas_screen.dart
// Idealmente, estes deveriam ser widgets globais em um arquivo separado (ex: widgets/status_widgets.dart)
class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentoSkeletonCard extends StatelessWidget {
  const _DocumentoSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Colors.grey.withValues(alpha: 0.2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 14,
              width: 200,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 150,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 100,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentoGridCard extends StatelessWidget {
  final Documento documento;
  final Function(String?) onOpen;

  const _DocumentoGridCard({required this.documento, required this.onOpen});

  Color _statusColor(DateTime validade) {
    final hoje = DateTime.now();
    final dias = validade.difference(hoje).inDays;

    if (validade.isBefore(hoje)) {
      return AppTheme.danger;
    }
    if (dias <= 30) {
      return AppTheme.warning;
    }
    return AppTheme.success;
  }

  String _statusLabel(DateTime validade) {
    final hoje = DateTime.now();
    final dias = validade.difference(hoje).inDays;

    if (validade.isBefore(hoje)) {
      return 'Vencido';
    }
    if (dias <= 30) {
      return 'A vencer';
    }
    return 'Em dia';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(documento.dataValidade);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onOpen(documento.arquivoPath),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    DocumentUtils.getIconForFileName(
                      documento.arquivoNome ?? '',
                    ),
                    color: statusColor,
                    size: 24,
                  ),
                  Chip(
                    label: Text(
                      _statusLabel(documento.dataValidade),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: statusColor,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                documento.tipoDocumentoNome ?? 'Documento',
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                documento.colaboradorNome ?? 'Colaborador nao identificado',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (documento.empresaNome != null)
                Text(
                  'Empresa: ${documento.empresaNome}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Text(
                'Validade: ${DateFormat('dd/MM/yyyy').format(documento.dataValidade)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Versao ${documento.versao}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
