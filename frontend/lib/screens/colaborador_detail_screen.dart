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
  // OBS: Assumindo que ApiService terá os métodos getColaboradorById e getVinculos.
  Colaborador? _colaborador;
  List<Documento> _documentos = [];
  List<Vinculo> _vinculos = [];
  bool _isLoading = true;
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
      // Carrega todos os dados em paralelo para melhor performance
      final resultados = await Future.wait([
        ApiService.getColaboradorById(widget.colaboradorId),
        ApiService.getVinculos(colaboradorId: widget.colaboradorId),
        ApiService.getDocumentos(
          colaboradorId: widget.colaboradorId,
          limit: 100, // TODO: Implementar paginação
        ),
      ]);

      setState(() {
        _colaborador = resultados[0] as Colaborador;
        _vinculos = resultados[1] as List<Vinculo>;
        // O ApiService.getDocumentos retorna um PaginatedResponse.
        _documentos = (resultados[2] as PaginatedResponse<Documento>).items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
          // TODO: Adicionar ações como "Editar Colaborador" ou "Adicionar Documento"
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
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
        Text(
          'Empresas Vinculadas',
          style: Theme.of(context).textTheme.titleLarge,
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
              return ActionChip(
                avatar: Icon(Icons.business_center_outlined, size: 18),
                label: Text(vinculo.empresaNome ?? 'Empresa não informada'),
                onPressed: () =>
                    context.go('/dashboard/empresas/${vinculo.empresaId}'),
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
      ],
    );
  }
}
