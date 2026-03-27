import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:frontend/models/tipo_documento_model.dart';
import 'package:frontend/models/vinculo_model.dart';
import 'package:frontend/screens/vinculos_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_theme.dart';

class ColaboradorDetailScreen extends StatefulWidget {
  final Colaborador colaborador;

  const ColaboradorDetailScreen({super.key, required this.colaborador});

  @override
  State<ColaboradorDetailScreen> createState() =>
      _ColaboradorDetailScreenState();
}

class _ColaboradorDetailScreenState extends State<ColaboradorDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Documento> _documentos = [];
  List<Vinculo> _vinculos = [];
  List<Empresa> _empresas = [];
  List<TipoDocumento> _tiposDocumento = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        ApiService.getDocumentosPorColaborador(widget.colaborador.id!),
        ApiService.getVinculosPorColaborador(widget.colaborador.id!),
        ApiService.getEmpresas(),
        ApiService.getTiposDocumento(),
      ]);

      final docs = results[0] as List<Documento>;
      final vinculos = results[1] as List<Vinculo>;
      final empresas = results[2] as List<Empresa>;
      final tipos = results[3] as List<TipoDocumento>;

      final empresaIds = vinculos.map((v) => v.empresaId).toSet();
      final empresasVinculadas =
          empresas.where((empresa) => empresaIds.contains(empresa.id)).toList()
            ..sort((a, b) => a.nome.compareTo(b.nome));

      setState(() {
        _documentos = docs;
        _vinculos = vinculos;
        _empresas = empresasVinculadas;
        _tiposDocumento = tipos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) {
        return;
      }
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

  Future<void> _mostrarHistorico(Documento documento) async {
    try {
      final historico = await ApiService.getHistoricoDocumento(documento.id!);

      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historico de versoes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: historico.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = historico[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            '${item.tipoDocumentoNome ?? 'Documento'} - versao ${item.versao}',
                          ),
                          subtitle: Text(
                            'Validade: ${DateFormat('dd/MM/yyyy').format(item.dataValidade)}',
                          ),
                          trailing: item.arquivoPath != null
                              ? IconButton(
                                  onPressed: () =>
                                      _abrirArquivo(item.arquivoPath),
                                  icon: const Icon(Icons.open_in_new),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Color _getStatusColor(DateTime validade) {
    final hoje = DateTime.now();
    final validadeNormalizada = DateTime(
      validade.year,
      validade.month,
      validade.day,
    );
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);

    if (validadeNormalizada.isBefore(hojeNormalizado)) {
      return AppTheme.danger;
    }
    if (validadeNormalizada.difference(hojeNormalizado).inDays <= 30) {
      return AppTheme.warning;
    }
    return AppTheme.success;
  }

  String _statusTexto(DateTime validade) {
    final hoje = DateTime.now();
    final validadeNormalizada = DateTime(
      validade.year,
      validade.month,
      validade.day,
    );
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);

    if (validadeNormalizada.isBefore(hojeNormalizado)) {
      return 'Vencido';
    }
    if (validadeNormalizada.difference(hojeNormalizado).inDays <= 30) {
      return 'A vencer';
    }
    return 'Em dia';
  }

  Future<DateTime?> _selecionarData() async {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
  }

  Future<void> _anexarDocumento({
    Documento? documentoExistente,
    int? empresaId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result == null) {
      return;
    }

    if (documentoExistente != null) {
      final novaData = await _selecionarData();
      if (novaData == null) {
        return;
      }
      await _realizarUpload(
        result,
        documentoExistente: documentoExistente,
        novaValidade: novaData,
      );
      return;
    }

    final tiposFiltrados = _tiposDocumento.where((tipo) {
      return empresaId == null
          ? tipo.tipo == 'pessoal'
          : tipo.tipo == 'empresa';
    }).toList();

    TipoDocumento? tipoSelecionado;
    DateTime? dataSelecionada;

    if (!mounted) {
      return;
    }

    if (tiposFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum tipo de documento disponivel')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
              empresaId == null
                  ? 'Novo documento pessoal'
                  : 'Novo documento empresarial',
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TipoDocumento>(
                    initialValue: tipoSelecionado,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: tiposFiltrados.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo.nome),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() => tipoSelecionado = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selecionada = await _selecionarData();
                      if (selecionada != null) {
                        setStateDialog(() => dataSelecionada = selecionada);
                      }
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      dataSelecionada == null
                          ? 'Selecionar validade'
                          : DateFormat('dd/MM/yyyy').format(dataSelecionada!),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: tipoSelecionado != null && dataSelecionada != null
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmar != true ||
        tipoSelecionado == null ||
        dataSelecionada == null) {
      return;
    }

    await _realizarUpload(
      result,
      empresaId: empresaId,
      tipoDocumentoId: tipoSelecionado!.id,
      novaValidade: dataSelecionada!,
    );
  }

  Future<void> _realizarUpload(
    FilePickerResult arquivo, {
    Documento? documentoExistente,
    int? empresaId,
    int? tipoDocumentoId,
    required DateTime novaValidade,
  }) async {
    try {
      final dataStr = DateFormat('yyyy-MM-dd').format(novaValidade);

      if (documentoExistente != null) {
        await ApiService.uploadArquivo(
          arquivo,
          documentoId: documentoExistente.id,
          novaValidade: dataStr,
        );
      } else {
        final resposta = await ApiService.uploadArquivo(arquivo);
        final arquivoPath = resposta['file']?['path'] as String?;
        final arquivoNome =
            resposta['file']?['originalname'] as String? ??
            arquivo.files.single.name;

        if (arquivoPath == null) {
          throw Exception('O servidor nao retornou o caminho do arquivo');
        }

        await ApiService.createDocumento(
          Documento(
            colaboradorId: widget.colaborador.id!,
            empresaId: empresaId,
            tipoDocumentoId: tipoDocumentoId!,
            dataValidade: novaValidade,
            arquivoNome: arquivoNome,
            arquivoPath: arquivoPath,
            observacoes: null,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento salvo com sucesso')),
      );
      await _carregarDados();
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildDocumentoCard(Documento doc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _getStatusColor(doc.dataValidade),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.tipoDocumentoNome ?? 'Documento sem tipo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Validade: ${DateFormat('dd/MM/yyyy').format(doc.dataValidade)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(_statusTexto(doc.dataValidade))),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Versao ${doc.versao}')),
                if (doc.empresaNome != null)
                  Chip(label: Text(doc.empresaNome!)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (doc.arquivoPath != null)
                  OutlinedButton.icon(
                    onPressed: () => _abrirArquivo(doc.arquivoPath),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir anexo'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _mostrarHistorico(doc),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Historico'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _anexarDocumento(documentoExistente: doc),
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Substituir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentosPessoais() {
    final docsPessoais = _documentos.where((d) => d.empresaId == null).toList();
    if (docsPessoais.isEmpty) {
      return const Center(child: Text('Nenhum documento pessoal cadastrado'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: docsPessoais.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildDocumentoCard(docsPessoais[index]),
    );
  }

  Widget _buildDocumentosEmpresa() {
    if (_empresas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, size: 42),
              const SizedBox(height: 12),
              const Text('Nenhuma empresa vinculada'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VinculosScreen(colaborador: widget.colaborador),
                    ),
                  );
                  await _carregarDados();
                },
                child: const Text('Gerenciar vinculos'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _empresas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final empresa = _empresas[index];
        final docsEmpresa = _documentos
            .where((d) => d.empresaId == empresa.id)
            .toList();

        return Card(
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text(empresa.nome),
            subtitle: Text(
              '${docsEmpresa.length} documento(s) ativo(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => _anexarDocumento(empresaId: empresa.id),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar'),
            ),
            children: [
              if (docsEmpresa.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nenhum documento empresarial para esta empresa',
                    ),
                  ),
                )
              else
                ...docsEmpresa.map(
                  (doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDocumentoCard(doc),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.colaborador.nome),
        actions: [
          IconButton(
            tooltip: 'Gerenciar vinculos',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VinculosScreen(colaborador: widget.colaborador),
                ),
              );
              await _carregarDados();
            },
            icon: const Icon(Icons.account_tree_outlined),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pessoais'),
            Tab(text: 'Por empresa'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _anexarDocumento(),
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Novo pessoal'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(
                          widget.colaborador.email?.isNotEmpty == true
                              ? widget.colaborador.email!
                              : 'Sem e-mail',
                        ),
                      ),
                      Chip(
                        label: Text(
                          widget.colaborador.telefone?.isNotEmpty == true
                              ? widget.colaborador.telefone!
                              : 'Sem telefone',
                        ),
                      ),
                      Chip(label: Text('${_vinculos.length} vinculo(s)')),
                      Chip(label: Text('${_documentos.length} documento(s)')),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDocumentosPessoais(),
                      _buildDocumentosEmpresa(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
