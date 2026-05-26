import 'package:flutter/material.dart';
import 'package:frontend/models/tipo_documento_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_theme.dart';

class TiposDocumentoScreen extends StatefulWidget {
  const TiposDocumentoScreen({super.key});

  @override
  State<TiposDocumentoScreen> createState() => _TiposDocumentoScreenState();
}

class _TiposDocumentoScreenState extends State<TiposDocumentoScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<TipoDocumento> _tipos = [];

  @override
  void initState() {
    super.initState();
    _carregarTipos();
  }

  Future<void> _carregarTipos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final tipos = await ApiService.getTiposDocumento();
      setState(() {
        _tipos = tipos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirFormulario([TipoDocumento? tipoExistente]) async {
    final nomeController = TextEditingController(text: tipoExistente?.nome ?? '');
    final descricaoController = TextEditingController(
      text: tipoExistente?.descricao ?? '',
    );
    String categoria = tipoExistente?.tipo ?? 'empresa';
    bool salvando = false;
    final formKey = GlobalKey<FormState>();

    final salvo = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> salvar() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() => salvando = true);
            try {
              if (tipoExistente == null) {
                await ApiService.createTipoDocumento(
                  nome: nomeController.text.trim(),
                  tipo: categoria,
                  descricao: descricaoController.text.trim().isEmpty
                      ? null
                      : descricaoController.text.trim(),
                );
              } else {
                await ApiService.updateTipoDocumento(
                  id: tipoExistente.id,
                  nome: nomeController.text.trim(),
                  tipo: categoria,
                  descricao: descricaoController.text.trim().isEmpty
                      ? null
                      : descricaoController.text.trim(),
                );
              }
              if (!context.mounted) return;
              Navigator.pop(context, true);
            } catch (e) {
              if (!context.mounted) return;
              setDialogState(() => salvando = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                ),
              );
            }
          }

          return AlertDialog(
            title: Text(
              tipoExistente == null
                  ? 'Novo tipo de documento'
                  : 'Editar tipo de documento',
            ),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nomeController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o nome do tipo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categoria,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: const [
                        DropdownMenuItem(
                          value: 'empresa',
                          child: Text('Empresa'),
                        ),
                        DropdownMenuItem(
                          value: 'pessoal',
                          child: Text('Pessoal'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => categoria = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descricaoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descricao (opcional)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: salvando ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: salvando ? null : salvar,
                child: salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );

    nomeController.dispose();
    descricaoController.dispose();

    if (salvo == true) {
      await _carregarTipos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tipoExistente == null
                ? 'Tipo criado com sucesso'
                : 'Tipo atualizado com sucesso',
          ),
        ),
      );
    }
  }

  Future<void> _confirmarExclusao(TipoDocumento tipo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tipo de documento'),
        content: Text('Deseja remover "${tipo.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.deleteTipoDocumento(tipo.id);
      await _carregarTipos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo removido com sucesso')),
      );
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
      appBar: AppBar(title: const Text('Tipos de documento')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo tipo'),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarTipos,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                'Cadastre e mantenha os tipos de documento usados no sistema (pessoal e empresa).',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(_errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _carregarTipos,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_tipos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nenhum tipo cadastrado ainda.'),
                ),
              )
            else
              ..._tipos.map(
                (tipo) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tipo.tipo == 'empresa'
                            ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                            : AppTheme.primaryGreen.withValues(alpha: 0.12),
                        foregroundColor: tipo.tipo == 'empresa'
                            ? AppTheme.primaryBlue
                            : AppTheme.primaryGreen,
                        child: Icon(
                          tipo.tipo == 'empresa'
                              ? Icons.apartment_rounded
                              : Icons.person_rounded,
                        ),
                      ),
                      title: Text(tipo.nome),
                      subtitle: Text(
                        '${tipo.tipo.toUpperCase()}${tipo.descricao?.isNotEmpty == true ? ' • ${tipo.descricao}' : ''}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'editar') {
                            _abrirFormulario(tipo);
                          } else if (value == 'excluir') {
                            _confirmarExclusao(tipo);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'editar',
                            child: Text('Editar'),
                          ),
                          PopupMenuItem(
                            value: 'excluir',
                            child: Text('Excluir'),
                          ),
                        ],
                      ),
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
