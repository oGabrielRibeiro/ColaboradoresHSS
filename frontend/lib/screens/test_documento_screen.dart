import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/models/tipo_documento.dart';
import 'package:frontend/models/vinculo_model.dart';
import 'package:frontend/services/api_service.dart';

/// Tela de teste para criação e substituição de documentos.
/// Implementa validações de:
/// - Data de validade (não pode ser no passado)
/// - Tipos de arquivo permitidos
/// - Tamanho máximo de arquivo
class TestDocumentoScreen extends StatefulWidget {
  final int colaboradorId;
  const TestDocumentoScreen({super.key, required this.colaboradorId});

  @override
  State<TestDocumentoScreen> createState() => _TestDocumentoScreenState();
}

class _TestDocumentoScreenState extends State<TestDocumentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataController = TextEditingController();
  final _observacoesController = TextEditingController();

  List<TipoDocumento> _tiposDocumento = [];
  List<Vinculo> _vinculos = [];
  int? _tipoDocumentoIdSelecionado;
  int? _empresaIdSelecionado;
  String? _arquivoNome;
  String? _arquivoPath;
  DateTime? _dataValidadeSelecionada;

  String? _errorMessage;
  bool _isLoading = true;
  bool _isUploading = false;

  // Configurações de validação
  static const int tamanhoMaximoArquivoMB = 10;
  static const List<String> tiposArquivoPermitidos = [
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.jpg',
    '.jpeg',
    '.png'
  ];

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _dataController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tipos = await ApiService.getTiposDocumento();
      final vinculos = await ApiService.getVinculos(colaboradorId: widget.colaboradorId);

      setState(() {
        _tiposDocumento = tipos;
        _vinculos = vinculos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _selecionarArquivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validar tamanho
        if (file.size > tamanhoMaximoArquivoMB * 1024 * 1024) {
          setState(() {
            _errorMessage = 'Arquivo excede o tamanho máximo de $tamanhoMaximoArquivoMB MB';
          });
          return;
        }

        // Validar extensão
        final extensao = '.${file.extension ?? ''}';
        if (!tiposArquivoPermitidos.contains(extensao.toLowerCase())) {
          setState(() {
            _errorMessage = 'Tipo de arquivo não permitido. Use: ${tiposArquivoPermitidos.join(', ')}';
          });
          return;
        }

        setState(() {
          _arquivoNome = file.name;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao selecionar arquivo: ${e.toString()}';
      });
    }
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final primeiraData = hoje;

    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: primeiraData,
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
      helpText: 'DATA DE VALIDADE',
      cancelText: 'CANCELAR',
      confirmText: 'OK',
      fieldLabelText: 'DIGITE A DATA',
      errorFormatText: 'Formato inválido',
      errorInvalidText: 'Data inválida',
    );

    if (dataSelecionada != null) {
      setState(() {
        _dataValidadeSelecionada = dataSelecionada;
        _dataController.text = _formatarData(dataSelecionada);
      });
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Future<void> _criarDocumento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dataValidadeSelecionada == null) {
      setState(() {
        _errorMessage = 'Selecione uma data de validade';
      });
      return;
    }

    if (_arquivoNome == null) {
      setState(() {
        _errorMessage = 'Selecione um arquivo';
      });
      return;
    }

    // Determinar categoria do documento
    final tipoDoc = _tiposDocumento.firstWhere(
      (t) => t.id == _tipoDocumentoIdSelecionado,
    );

    // Validar regras de negócio
    if (tipoDoc.tipo == 'empresa' && _empresaIdSelecionado == null) {
      setState(() {
        _errorMessage = 'Documentos empresariais requerem uma empresa vinculada';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implementar upload real do arquivo
      // Por enquanto, criamos com path mockado
      final arquivoPath = '/uploads/$_arquivoNome';

      final novoDocumento = Documento(
        colaboradorId: widget.colaboradorId,
        tipoDocumentoId: _tipoDocumentoIdSelecionado!,
        dataValidade: _dataValidadeSelecionada!,
        arquivoNome: _arquivoNome!,
        arquivoPath: arquivoPath,
        empresaId: tipoDoc.tipo == 'empresa' ? _empresaIdSelecionado : null,
        observacoes: _observacoesController.text,
      );

      await ApiService.createDocumento(novoDocumento);

      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento criado com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Documento (Teste)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDadosIniciais,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tipo de Documento
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Documento *',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),n                    value: _tipoDocumentoIdSelecionado,
                    items: _tiposDocumento.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo.id,
                        child: Text(tipo.nome),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _tipoDocumentoIdSelecionado = value;
                        _empresaIdSelecionado = null;
                      });
                    },
                    validator: (value) => value == null ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),

                  // Empresa (só aparece se for documento empresarial)
                  if (_tipoDocumentoIdSelecionado != null &&
                      _tiposDocumento.isNotEmpty &&
                      _tiposDocumento
                          .firstWhere((t) => t.id == _tipoDocumentoIdSelecionado)
                          .tipo ==
                          'empresa') ...[
                    DropdownButtonFormField<int>(n                      decoration: const InputDecoration(
                        labelText: 'Empresa *',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      value: _empresaIdSelecionado,
                      items: _vinculos.map((vinculo) {
                        return DropdownMenuItem(
                          value: vinculo.empresaId,
                          child: Text(vinculo.empresaNome ?? 'Empresa #${vinculo.empresaId}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _empresaIdSelecionado = value;
                        });
                      },
                      validator: (value) => value == null ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Data de Validade
                  TextFormField(
                    controller: _dataController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Data de Validade *',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                      hintText: 'Selecione uma data',
                    ),
                    onTap: _selecionarData,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Observações
                  TextFormField(
                    controller: _observacoesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      prefixIcon: Icon(Icons.note_outlined),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Seleção de Arquivo
                  Card(
                    child: InkWell(
                      onTap: _selecionarArquivo,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.upload_file, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _arquivoNome ?? 'Clique para selecionar arquivo',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tamanho máximo: $tamanhoMaximoArquivoMB MB\nTipos permitidos: PDF, DOC, DOCX, XLS, XLSX, JPG, PNG',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton(
                    onPressed: _isUploading ? null : _criarDocumento,
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('CRIAR DOCUMENTO'),
                  ),
                ],
              ),
            ),
    );
  }
}
