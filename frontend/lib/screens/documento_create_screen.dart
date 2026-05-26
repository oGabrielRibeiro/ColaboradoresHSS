import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/models/paginated_response.dart';
import 'package:frontend/models/tipo_documento_model.dart';
import 'package:frontend/models/vinculo_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/widgets/drag_and_drop_area.dart';

class DocumentoCreateScreen extends StatefulWidget {
  final int? colaboradorIdInicial;

  const DocumentoCreateScreen({super.key, this.colaboradorIdInicial});

  @override
  State<DocumentoCreateScreen> createState() => _DocumentoCreateScreenState();
}

class _DocumentoCreateScreenState extends State<DocumentoCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observacoesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  List<Colaborador> _colaboradores = [];
  List<TipoDocumento> _tiposDocumento = [];
  List<Vinculo> _vinculosColaborador = [];

  int? _colaboradorId;
  int? _tipoDocumentoId;
  int? _empresaId;
  DateTime? _dataValidade;
  FilePickerResult? _arquivo;

  @override
  void initState() {
    super.initState();
    _colaboradorId = widget.colaboradorIdInicial;
    _carregarBase();
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  TipoDocumento? get _tipoSelecionado {
    for (final tipo in _tiposDocumento) {
      if (tipo.id == _tipoDocumentoId) return tipo;
    }
    return null;
  }

  bool get _isTipoEmpresa => _tipoSelecionado?.tipo == 'empresa';

  Future<void> _carregarBase() async {
    setState(() => _isLoading = true);
    try {
      final resultados = await Future.wait([
        ApiService.getColaboradores(limit: 1000),
        ApiService.getTiposDocumento(),
      ]);

      final colaboradoresResponse =
          resultados[0] as PaginatedResponse<Colaborador>;
      final colaboradores = colaboradoresResponse.items;
      final tipos = resultados[1] as List<TipoDocumento>;

      setState(() {
        _colaboradores = colaboradores;
        _tiposDocumento = tipos;
        _isLoading = false;
      });

      if (_colaboradorId != null) {
        await _carregarVinculosColaborador(_colaboradorId!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _carregarVinculosColaborador(int colaboradorId) async {
    try {
      final vinculos = await ApiService.getVinculos(colaboradorId: colaboradorId);
      setState(() {
        _vinculosColaborador = vinculos;
        final empresaAindaExiste = vinculos.any((v) => v.empresaId == _empresaId);
        if (!empresaAindaExiste) {
          _empresaId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _selecionarDataValidade() async {
    final agora = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: _dataValidade ?? agora,
      firstDate: DateTime(agora.year, agora.month, agora.day),
      lastDate: DateTime(agora.year + 10),
    );
    if (data == null) return;
    setState(() => _dataValidade = data);
  }

  Future<void> _salvarDocumento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_arquivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um arquivo para continuar.')),
      );
      return;
    }

    if (_colaboradorId == null || _tipoDocumentoId == null || _dataValidade == null) {
      return;
    }

    if (_isTipoEmpresa && _empresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vincule o colaborador a uma empresa antes de enviar documento empresarial.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final upload = await ApiService.uploadArquivo(_arquivo!);
      final arquivoNome =
          (upload['arquivo_nome'] ?? _arquivo!.files.single.name).toString();
      final arquivoPath =
          (upload['arquivo_path'] ?? upload['path'] ?? '').toString();

      if (arquivoPath.isEmpty) {
        throw Exception('Upload sem caminho de arquivo retornado pela API');
      }

      await ApiService.createDocumento(
        Documento(
          colaboradorId: _colaboradorId!,
          empresaId: _isTipoEmpresa ? _empresaId : null,
          tipoDocumentoId: _tipoDocumentoId!,
          dataValidade: _dataValidade!,
          arquivoNome: arquivoNome,
          arquivoPath: arquivoPath,
          observacoes: _observacoesController.text.trim().isEmpty
              ? null
              : _observacoesController.text.trim(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento cadastrado com sucesso.')),
      );
      context.go('/dashboard/colaboradores/${_colaboradorId!}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novo documento')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF6EE), Color(0xFFE8EEFF)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'Cadastre documentos com validação por tipo. Documentos empresariais exigem vínculo ativo do colaborador com a empresa.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _colaboradorId,
                      decoration: const InputDecoration(labelText: 'Colaborador'),
                      items: _colaboradores
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.nome),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) async {
                              if (value == null) return;
                              setState(() {
                                _colaboradorId = value;
                                _empresaId = null;
                                _vinculosColaborador = [];
                              });
                              await _carregarVinculosColaborador(value);
                            },
                      validator: (value) =>
                          value == null ? 'Selecione o colaborador' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _tipoDocumentoId,
                      decoration: const InputDecoration(labelText: 'Tipo de documento'),
                      items: _tiposDocumento
                          .map(
                            (tipo) => DropdownMenuItem<int>(
                              value: tipo.id,
                              child: Text('${tipo.nome} (${tipo.tipo})'),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _tipoDocumentoId = value;
                                if (!_isTipoEmpresa) {
                                  _empresaId = null;
                                }
                              });
                            },
                      validator: (value) =>
                          value == null ? 'Selecione o tipo de documento' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_isTipoEmpresa) ...[
                      DropdownButtonFormField<int>(
                        initialValue: _empresaId,
                        decoration: const InputDecoration(
                          labelText: 'Empresa vinculada',
                          hintText: 'Selecione uma empresa vinculada',
                        ),
                        items: _vinculosColaborador
                            .map(
                              (v) => DropdownMenuItem<int>(
                                value: v.empresaId,
                                child: Text(v.empresaNome ?? 'Empresa #${v.empresaId}'),
                              ),
                            )
                            .toList(),
                        onChanged: _isSaving ? null : (value) => setState(() => _empresaId = value),
                        validator: (value) {
                          if (_isTipoEmpresa && value == null) {
                            return 'Selecione a empresa vinculada';
                          }
                          return null;
                        },
                      ),
                      if (_vinculosColaborador.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            onPressed: _colaboradorId == null
                                ? null
                                : () => context.push(
                                      '/dashboard/colaboradores/${_colaboradorId!}',
                                    ),
                            icon: const Icon(Icons.link_rounded),
                            label: const Text(
                              'Sem vínculo ativo. Abra o colaborador para vincular empresa.',
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      readOnly: true,
                      onTap: _isSaving ? null : _selecionarDataValidade,
                      decoration: InputDecoration(
                        labelText: 'Data de validade',
                        hintText: _dataValidade == null
                            ? 'Selecione a data'
                            : '${_dataValidade!.day.toString().padLeft(2, '0')}/${_dataValidade!.month.toString().padLeft(2, '0')}/${_dataValidade!.year}',
                        suffixIcon: const Icon(Icons.calendar_today_rounded),
                      ),
                      validator: (_) =>
                          _dataValidade == null ? 'Informe a data de validade' : null,
                    ),
                    const SizedBox(height: 12),
                    DragAndDropArea(
                      isLoading: _isSaving,
                      currentFileName: _arquivo?.files.single.name,
                      onFilePicked: (result) {
                        setState(() => _arquivo = result);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _observacoesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações (opcional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _salvarDocumento,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving ? 'Salvando documento...' : 'Salvar documento',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
