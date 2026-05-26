import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// OBS: Os models `Colaborador` e `Vinculo` precisam ser criados. O código
// abaixo assume que eles existem.
import 'package:frontend/models/colaborador_model.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/models/vinculo_model.dart';
import 'package:frontend/models/paginated_response.dart';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/documento_card.dart';

class ColaboradorDetailScreen extends StatefulWidget {
  final int colaboradorId;
  const ColaboradorDetailScreen({super.key, required this.colaboradorId});

  @override
  State<ColaboradorDetailScreen> createState() =>
      _ColaboradorDetailScreenState();
}

class _ColaboradorDetailScreenState extends State<ColaboradorDetailScreen> {
  static const int _documentosPageSize = 20;

  Colaborador? _colaborador;
  List<Documento> _documentos = [];
  List<Vinculo> _vinculos = [];
  bool _isLoading = true;
  bool _isLoadingMoreDocumentos = false;
  bool _hasMoreDocumentos = true;
  int _documentosPage = 1;
  String _errorMessage = '';

  Future<void> _abrirDialogVincularEmpresa() async {
    try {
      final empresasResponse = await ApiService.getEmpresas(limit: 1000);
      final idsVinculados = _vinculos.map((item) => item.empresaId).toSet();
      final disponiveis = empresasResponse.items
          .where(
            (empresa) =>
                empresa.id != null && !idsVinculados.contains(empresa.id),
          )
          .toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));

      if (!mounted) return;

      if (disponiveis.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas as empresas já estão vinculadas.')),
        );
        return;
      }

      int? empresaSelecionadaId;

      final empresaId = await showDialog<int>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Vincular empresa'),
            content: SizedBox(
              width: 420,
              child: DropdownButtonFormField<int>(
                initialValue: empresaSelecionadaId,
                decoration: const InputDecoration(
                  labelText: 'Empresa',
                  hintText: 'Selecione uma empresa',
                ),
                items: disponiveis.map((empresa) {
                  return DropdownMenuItem<int>(
                    value: empresa.id,
                    child: Text(empresa.nome),
                  );
                }).toList(),
                onChanged: (value) {
                  setStateDialog(() => empresaSelecionadaId = value);
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: empresaSelecionadaId == null
                    ? null
                    : () => Navigator.pop(context, empresaSelecionadaId),
                child: const Text('Vincular'),
              ),
            ],
          ),
        ),
      );

      if (empresaId == null) {
        return;
      }

      await ApiService.createVinculo(
        Vinculo(colaboradorId: widget.colaboradorId, empresaId: empresaId),
      );
      await _carregarDados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa vinculada com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _desvincularEmpresa(Vinculo vinculo) async {
    if (vinculo.id == null) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover vínculo'),
        content: Text(
          'Deseja remover o vínculo com "${vinculo.empresaNome ?? 'esta empresa'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    try {
      await ApiService.deleteVinculo(vinculo.id!);
      await _carregarDados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vínculo removido com sucesso')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

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
      // Carrega todos os dados em paralelo para melhor performance
      final resultados = await Future.wait([
        ApiService.getColaboradorById(widget.colaboradorId),
        ApiService.getVinculos(colaboradorId: widget.colaboradorId),
        ApiService.getDocumentos(
          colaboradorId: widget.colaboradorId,
          page: 1,
          limit: _documentosPageSize,
        ),
      ]);

      setState(() {
        _colaborador = resultados[0] as Colaborador;
        _vinculos = resultados[1] as List<Vinculo>;
        final documentosResponse = resultados[2] as PaginatedResponse<Documento>;
        _documentos = documentosResponse.items;
        _documentosPage = 1;
        _hasMoreDocumentos = documentosResponse.hasMore;
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
        colaboradorId: widget.colaboradorId,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_colaborador?.nome ?? 'Detalhes do Colaborador'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'recarregar') {
                await _carregarDados();
                return;
              }
              if (!mounted) return;
              if (value == 'editar') {
                context.go('/dashboard/colaboradores');
              } else if (value == 'adicionar_documento') {
                context.go(
                  '/dashboard/documentos/novo?colaborador_id=${widget.colaboradorId}',
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'recarregar', child: Text('Recarregar')),
              PopupMenuItem(
                value: 'editar',
                child: Text('Editar colaborador (lista)'),
              ),
              PopupMenuItem(
                value: 'adicionar_documento',
                child: Text('Adicionar documento (atalho)'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _carregarDados, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
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
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildColaboradorHeader(),
        const SizedBox(height: 24),
        _buildVinculosSection(),
        const SizedBox(height: 24),
        _buildDocumentosSection(),
      ],
    );
  }

  Widget _buildColaboradorHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _colaborador!.nome,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (_colaborador!.cargo != null) ...[
            const SizedBox(height: 4),
            Text(
              _colaborador!.cargo!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 16),
          if (_colaborador!.cpf?.isNotEmpty == true)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.badge_outlined),
              title: const Text('CPF'),
              subtitle: Text(_colaborador!.cpf!),
            ),
        ],
      ),
    );
  }

  Widget _buildVinculosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Empresas Vinculadas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _abrirDialogVincularEmpresa,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Vincular'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => context.push(
                '/dashboard/documentos/novo?colaborador_id=${widget.colaboradorId}',
              ),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Novo documento'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_vinculos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('Nenhum vínculo com empresas.')),
            ),
          )
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _vinculos.map((vinculo) {
              return InputChip(
                avatar: const Icon(Icons.business_center_outlined, size: 18),
                label: Text(vinculo.empresaNome ?? 'Empresa não informada'),
                onPressed: () =>
                    context.go('/dashboard/empresas/${vinculo.empresaId}'),
                onDeleted: () => _desvincularEmpresa(vinculo),
                deleteIcon: const Icon(Icons.close_rounded, size: 18),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDocumentosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documentos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_documentos.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('Nenhum documento encontrado.')),
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
      ],
    );
  }
}
