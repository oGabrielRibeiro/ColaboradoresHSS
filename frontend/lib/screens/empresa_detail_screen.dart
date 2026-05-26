import 'package:flutter/material.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/models/empresa_model.dart';
<<<<<<< HEAD
import 'package:frontend/models/paginated_response.dart';
import 'package:frontend/models/vinculo_model.dart';
=======
>>>>>>> 14e77d995daeddfa9c1120877bb980936b9b3e70
import 'package:frontend/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/widgets/documento_card.dart';
import 'package:go_router/go_router.dart';

class EmpresaDetailScreen extends StatefulWidget {
  final int empresaId;
  const EmpresaDetailScreen({super.key, required this.empresaId});

  @override
  State<EmpresaDetailScreen> createState() => _EmpresaDetailScreenState();
}

class _EmpresaDetailScreenState extends State<EmpresaDetailScreen> {
  static const int _documentosPageSize = 20;

  Empresa? _empresa;
  List<Documento> _documentos = [];
  List<Vinculo> _vinculos = [];
  bool _isLoading = true;
  bool _isLoadingMoreDocumentos = false;
  bool _hasMoreDocumentos = true;
  int _documentosPage = 1;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final resultados = await Future.wait([
        ApiService.getEmpresaById(widget.empresaId),
        ApiService.getDocumentos(
          empresaId: widget.empresaId,
          page: 1,
          limit: _documentosPageSize,
        ),
        ApiService.getVinculos(empresaId: widget.empresaId),
      ]);

      setState(() {
        _empresa = resultados[0] as Empresa;
        final documentosResponse =
            resultados[1] as PaginatedResponse<Documento>;
        _documentos = documentosResponse.items;
        _documentosPage = 1;
        _hasMoreDocumentos = documentosResponse.hasMore;
        _vinculos = resultados[2] as List<Vinculo>;
        _isLoadingMoreDocumentos = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _carregarMaisDocumentos() async {
    if (_isLoadingMoreDocumentos || !_hasMoreDocumentos) {
      return;
    }

    setState(() => _isLoadingMoreDocumentos = true);
    try {
      final nextPage = _documentosPage + 1;
      final response = await ApiService.getDocumentos(
        empresaId: widget.empresaId,
        page: nextPage,
        limit: _documentosPageSize,
      );
      setState(() {
        _documentos.addAll(response.items);
        _documentosPage = nextPage;
        _hasMoreDocumentos = response.hasMore;
        _isLoadingMoreDocumentos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMoreDocumentos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
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
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nao foi possivel abrir o arquivo')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_empresa?.nome ?? 'Detalhes da Empresa')),
      body: RefreshIndicator(
        onRefresh: _carregarDados,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarDados,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
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
                          _empresa!.nome,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (_empresa!.cnpj?.isNotEmpty == true)
                          ListTile(
                            leading: const Icon(Icons.business_center_outlined),
                            title: const Text('CNPJ'),
                            subtitle: Text(_empresa!.cnpj!),
                          ),
                        if (_empresa!.contato?.isNotEmpty == true)
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Contato'),
                            subtitle: Text(_empresa!.contato!),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Documentos Associados',
                    style: Theme.of(context).textTheme.titleLarge,
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
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Novo documento'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_documentos.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            'Nenhum documento encontrado para esta empresa.',
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _documentos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final doc = _documentos[index];
                            return DocumentoCard(
                              documento: doc,
                              onOpen: () => _abrirArquivo(doc.arquivoPath),
                            );
                          },
                        ),
                        if (_hasMoreDocumentos) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoadingMoreDocumentos
                                ? null
                                : _carregarMaisDocumentos,
                            icon: _isLoadingMoreDocumentos
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.expand_more_rounded),
                            label: Text(
                              _isLoadingMoreDocumentos
                                  ? 'Carregando...'
                                  : 'Carregar mais documentos',
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Colaboradores Vinculados',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_vinculos.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(
                          child: Text('Nenhum colaborador vinculado a esta empresa.'),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _vinculos.map((vinculo) {
                        return ActionChip(
                          avatar: const Icon(Icons.person_outline_rounded, size: 18),
                          label: Text(vinculo.colaboradorNome ?? 'Colaborador'),
                          onPressed: () => context.go(
                            '/dashboard/colaboradores/${vinculo.colaboradorId}',
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
      ),
    );
  }
}
