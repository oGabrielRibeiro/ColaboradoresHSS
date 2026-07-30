import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import 'package:frontend/models/documento_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/widgets/documento_card.dart';
import 'package:frontend/widgets/documento_grid_card.dart';
import 'package:frontend/widgets/error_state_widget.dart';

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

  Future<void> _substituirDocumento(Documento documento) async {
    // 1. Selecionar novo arquivo
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result == null) return; // Usuário cancelou

    final file = result.files.single;

    // 2. Pedir nova data de validade
    if (!mounted) return;
    final novaData = await showDatePicker(
      context: context,
      initialDate: documento.dataValidade,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (novaData == null) return; // Usuário cancelou

    // 3. Mostrar diálogo de confirmação
    if (!mounted) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Substituição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documento: ${documento.tipoDocumentoNome} (v${documento.versao})',
            ),
            const SizedBox(height: 8),
            Text('Novo arquivo: ${file.name}'),
            const SizedBox(height: 8),
            Text('Nova validade: ${DateFormat('dd/MM/yyyy').format(novaData)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Substituir'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    // 4. Enviar para a API
    try {
      await ApiService.uploadArquivo(
        result,
        documentoId: documento.id,
        novaValidade: DateFormat('yyyy-MM-dd').format(novaData),
      );
      await _carregarDocumentos(); // Recarrega os documentos da tela
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento substituído com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao substituir: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
    }
  }

  Future<void> _mostrarHistorico(Documento documento) async {
    List<Documento>? historico;
    String? erro;

    // Mostra um diálogo de carregamento inicial
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      historico = await ApiService.getHistoricoDocumento(documento.id!);
    } catch (e) {
      erro = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        Navigator.pop(context); // Fecha o diálogo de carregamento
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Histórico de Versões'),
        content: SizedBox(
          width: 400,
          child: erro != null
              ? Text('Erro ao carregar histórico: $erro')
              : historico == null || historico.isEmpty
                  ? const Text('Nenhuma versão anterior encontrada.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: historico.length,
                      itemBuilder: (context, index) {
                        final versao = historico![index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('v${versao.versao}')),
                          title: Text(
                            'Validade: ${DateFormat('dd/MM/yyyy').format(versao.dataValidade)}',
                          ),
                          subtitle: Text(
                            'Enviado em: ${DateFormat('dd/MM/yyyy HH:mm').format(versao.createdAt!)}',
                          ),
                          onTap: () => _abrirArquivo(versao.arquivoPath),
                        );
                      },
                    ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
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
                        onPressed: () =>
                            context.push('/dashboard/documentos/novo'),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Novo documento'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildBody(),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty && _documentos.isEmpty) {
      return ErrorStateWidget(
        message: _errorMessage,
        onRetry: _carregarDocumentos,
      );
    }

    if (_documentos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nenhum documento encontrado para este filtro.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/dashboard/documentos/novo'),
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Cadastrar documento'),
              ),
            ],
          ),
        ),
      );
    }

    final itemCount = _documentos.length + (_isLoadingMore ? 1 : 0);

    if (_isGridView) {
      final screenWidth = MediaQuery.of(context).size.width;
      // Ajusta o número de colunas com base na largura da tela.
      final crossAxisCount = (screenWidth / 350).floor().clamp(2, 5);

      return GridView.builder(
        key: const PageStorageKey('documentosGridView'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == _documentos.length) {
            return _buildLoadingMoreIndicator();
          }
          return DocumentoGridCard(
            documento: _documentos[index],
            onOpen: () => _abrirArquivo(_documentos[index].arquivoPath),
          );
        },
      );
    }

    return ListView.builder(
      key: const PageStorageKey('documentosListView'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == _documentos.length) {
          return _buildLoadingMoreIndicator();
        }
        final documento = _documentos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DocumentoCard(
            documento: documento,
            onOpen: () => _abrirArquivo(documento.arquivoPath),
            onReplace: () => _substituirDocumento(documento),
            onShowHistory: () => _mostrarHistorico(documento),
          ),
        );
      },
    );
  }
}
