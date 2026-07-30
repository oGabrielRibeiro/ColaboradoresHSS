import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:frontend/models/vinculo_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:frontend/widgets/error_state_widget.dart';
import 'package:frontend/widgets/documento_card.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ColaboradorDetailScreen extends StatefulWidget {
  final String colaboradorId;

  const ColaboradorDetailScreen({super.key, required this.colaboradorId});

  @override
  State<ColaboradorDetailScreen> createState() =>
      _ColaboradorDetailScreenState();
}

class _ColaboradorDetailScreenState extends State<ColaboradorDetailScreen> {
  Colaborador? _colaborador;
  bool _isLoading = true;
  List<Vinculo> _vinculos = [];
  List<Documento> _documentos = [];
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
      _vinculos = [];
      _documentos = [];
    });

    try {
      final colaboradorIdInt = int.parse(widget.colaboradorId);
      final colaborador = await ApiService.getColaboradorById(colaboradorIdInt);
      final vinculos = await ApiService.getVinculos(colaboradorId: colaboradorIdInt);
      final documentosResponse = await ApiService.getDocumentos(colaboradorId: colaboradorIdInt, limit: 1000);

      setState(() {
        _colaborador = colaborador;
        _vinculos = vinculos;
        _documentos = documentosResponse.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirArquivo(String? arquivoPath) async {
    if (arquivoPath == null || arquivoPath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Arquivo não disponível')));
      return;
    }

    try {
      final signedUrl = await ApiService.getSignedFileUrl(arquivoPath);
      final url = Uri.parse(signedUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o arquivo')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
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
        documentoId: documento.id!,
        novaValidade: DateFormat('yyyy-MM-dd').format(novaData),
      );

      await _carregarDados(); // Recarrega os dados da tela

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento substituído com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao substituir: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_colaborador?.nome ?? 'Detalhes do Colaborador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return ErrorStateWidget(message: _errorMessage, onRetry: _carregarDados);
    }

    if (_colaborador == null) {
      return const EmptyStateWidget(
        title: 'Colaborador não encontrado',
        message: 'Não foi possível carregar os dados deste colaborador.',
        icon: Icons.person_off_outlined,
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    const wideLayoutThreshold = 950;

    if (screenWidth > wideLayoutThreshold) {
      // Layout largo com duas colunas
      return RefreshIndicator(
        onRefresh: _carregarDados,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildVinculosSection(),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              flex: 3,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [_buildDocumentosSection()],
              ),
            ),
          ],
        ),
      );
    } else {
      // Layout estreito com uma coluna
      return RefreshIndicator(
        onRefresh: _carregarDados,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildVinculosSection(),
            const SizedBox(height: 24),
            _buildDocumentosSection(),
          ],
        ),
      ); // Removed extra ')'
    }
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _colaborador!.nome,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (_colaborador!.email != null)
              Text('E-mail: ${_colaborador!.email}'),
            if (_colaborador!.telefone != null)
              Text('Telefone: ${_colaborador!.telefone}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/dashboard/documentos/novo?colaboradorId=${_colaborador!.id}',
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Novo Documento'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _gerenciarVinculos(),
                  icon: const Icon(Icons.link),
                  label: const Text('Gerenciar Vínculos'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVinculosSection() {
    final vinculos = _vinculos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vínculos com Empresas',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (vinculos.isEmpty)
          const EmptyStateWidget(
            title: 'Nenhum vínculo encontrado',
            message:
                'Use "Gerenciar Vínculos" para associar este colaborador a uma empresa.',
            icon: Icons.link_off,
          )
        else
          ...vinculos.map(
            (v) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.apartment),
                title: Text(v.empresaNome ?? 'Empresa não identificada'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push('/dashboard/empresas/${v.empresaId}');
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentosSection() {
    final documentos = _documentos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documentos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (documentos.isEmpty)
          const EmptyStateWidget(
            title: 'Nenhum documento encontrado',
            message: 'Use o botão "Novo Documento" para adicionar o primeiro.',
            icon: Icons.file_copy_outlined,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              final doc = documentos[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: DocumentoCard(
                  documento: doc,
                  onOpen: () => _abrirArquivo(doc.arquivoPath),
                  onReplace: () => _substituirDocumento(doc),
                  onShowHistory: () => _mostrarHistorico(doc),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _gerenciarVinculos() async {
    List<Empresa> todasEmpresas = [];
    List<int> idsVinculados = _vinculos.map((v) => v.empresaId).toList();
    Map<int, bool> selecao = {};

    try {
      todasEmpresas = (await ApiService.getEmpresas(
        page: 1,
        limit: 1000,
      )).items;
      for (var empresa in todasEmpresas) {
        selecao[empresa.id!] = idsVinculados.contains(empresa.id);
      }
    } catch (e) {
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao carregar empresas: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Gerenciar Vínculos'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: todasEmpresas.length,
                  itemBuilder: (context, index) {
                    final empresa = todasEmpresas[index];
                    return CheckboxListTile(
                      title: Text(empresa.nome),
                      value: selecao[empresa.id] ?? false,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          selecao[empresa.id!] = value ?? false;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final novosIds = selecao.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      try {
        await ApiService.atualizarVinculos(_colaborador!.id!, novosIds);
        await _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vínculos atualizados com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro ao atualizar vínculos: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
            ),
          );
        }
      }
    }
  }
}
