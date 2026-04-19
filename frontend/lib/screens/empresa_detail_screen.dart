import 'package:flutter/material.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/widgets/documento_card.dart';

class EmpresaDetailScreen extends StatefulWidget {
  final int empresaId;
  const EmpresaDetailScreen({super.key, required this.empresaId});

  @override
  State<EmpresaDetailScreen> createState() => _EmpresaDetailScreenState();
}

class _EmpresaDetailScreenState extends State<EmpresaDetailScreen> {
  Empresa? _empresa;
  List<Documento> _documentos = [];
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
      final empresa = await ApiService.getEmpresaById(
        widget.empresaId,
      ); // Mantido para clareza
      final documentosResponse = await ApiService.getDocumentos(
        empresaId: widget.empresaId,
        limit: 100, // TODO: Implementar paginacao
      );

      // TODO: Implementar endpoint para buscar colaboradores por empresa.
      // A API atual não suporta buscar colaboradores vinculados a uma empresa diretamente.
      // Seria necessário um endpoint como `GET /empresas/:id/colaboradores`
      // ou `GET /vinculos?empresa_id=:id`.

      setState(() {
        _empresa = empresa;
        // O ApiService.getDocumentos retorna um PaginatedResponse.
        _documentos = documentosResponse.items;
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
                  const SizedBox(height: 24),
                  Text(
                    'Colaboradores Vinculados',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.construction_rounded,
                              size: 32,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Em desenvolvimento',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'A listagem de colaboradores por empresa será adicionada em breve.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
