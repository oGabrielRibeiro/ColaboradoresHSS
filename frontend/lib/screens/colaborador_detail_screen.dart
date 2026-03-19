import 'package:flutter/material.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:frontend/models/vinculo_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ColaboradorDetailScreen extends StatefulWidget {
  final Colaborador colaborador;
  const ColaboradorDetailScreen({super.key, required this.colaborador});

  @override
  State<ColaboradorDetailScreen> createState() => _ColaboradorDetailScreenState();
}

class _ColaboradorDetailScreenState extends State<ColaboradorDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Documento> _documentos = [];
  List<Vinculo> _vinculos = [];
  List<Empresa> _empresas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final docs = await ApiService.getDocumentosPorColaborador(widget.colaborador.id!);
      final vinculos = await ApiService.getVinculosPorColaborador(widget.colaborador.id!);
      // Carregar empresas vinculadas
      List<Empresa> empresasVinculadas = [];
      for (var v in vinculos) {
        // Para simplificar, estamos pegando todas as empresas e filtrando
        // Idealmente, teria uma rota para buscar empresas por vinculo
        final todas = await ApiService.getEmpresas();
        empresasVinculadas.addAll(todas.where((e) => e.id == v.empresaId));
      }
      setState(() {
        _documentos = docs;
        _vinculos = vinculos;
        _empresas = empresasVinculadas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Color _getStatusColor(DateTime validade) {
    final hoje = DateTime.now();
    if (validade.isBefore(hoje)) return Colors.red;
    if (validade.difference(hoje).inDays <= 30) return Colors.orange;
    return Colors.green;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.colaborador.nome),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Documentos Pessoais'),
            Tab(text: 'Documentos por Empresa'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Aba Documentos Pessoais
                _buildDocumentosPessoais(),
                // Aba Documentos por Empresa
                _buildDocumentosEmpresa(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Futuramente: adicionar novo documento
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDocumentosPessoais() {
    final docsPessoais = _documentos.where((d) => d.empresaId == null).toList();
    if (docsPessoais.isEmpty) {
      return const Center(child: Text('Nenhum documento pessoal'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: docsPessoais.length,
      itemBuilder: (context, index) {
        final doc = docsPessoais[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(doc.dataValidade),
              child: Icon(
                Icons.description,
                color: Colors.white,
              ),
            ),
            title: Text('Documento ID: ${doc.tipoDocumentoId}'), // Idealmente buscar nome do tipo
            subtitle: Text('Válido até: ${DateFormat('dd/MM/yyyy').format(doc.dataValidade)}'),
            trailing: doc.arquivoPath != null
                ? IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      // Abrir visualização do arquivo
                    },
                  )
                : const Text('Sem arquivo'),
          ),
        );
      },
    );
  }

  Widget _buildDocumentosEmpresa() {
    if (_empresas.isEmpty) {
      return const Center(child: Text('Nenhuma empresa vinculada'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _empresas.length,
      itemBuilder: (context, index) {
        final empresa = _empresas[index];
        // Filtrar documentos da empresa
        final docsEmpresa = _documentos.where((d) => d.empresaId == empresa.id).toList();
        return ExpansionTile(
          title: Text(empresa.nome),
          subtitle: Text('${docsEmpresa.length} documento(s)'),
          children: docsEmpresa.map((doc) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(doc.dataValidade),
                radius: 12,
              ),
              title: Text('Tipo ID: ${doc.tipoDocumentoId}'),
              subtitle: Text('Vencimento: ${DateFormat('dd/MM/yyyy').format(doc.dataValidade)}'),
              trailing: doc.arquivoPath != null
                  ? const Icon(Icons.attach_file, size: 16)
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}