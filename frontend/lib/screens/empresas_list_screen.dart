import 'package:flutter/material.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_theme.dart';

class EmpresasListScreen extends StatefulWidget {
  const EmpresasListScreen({super.key});

  @override
  State<EmpresasListScreen> createState() => _EmpresasListScreenState();
}

class _EmpresasListScreenState extends State<EmpresasListScreen> {
  List<Empresa> _empresas = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
  }

  Future<void> _carregarEmpresas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final paginatedResponse = await ApiService.getEmpresas(
        page: 1,
        limit: 100,
      ); // Exemplo: carrega até 100
      setState(() {
        _empresas = paginatedResponse.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirFormulario([Empresa? empresa]) async {
    final nomeController = TextEditingController(text: empresa?.nome ?? '');
    final cnpjController = TextEditingController(text: empresa?.cnpj ?? '');
    final formKey = GlobalKey<FormState>();

    final salvo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(empresa == null ? 'Nova Empresa' : 'Editar Empresa'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome da Empresa'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: cnpjController,
                decoration: const InputDecoration(labelText: 'CNPJ (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final payload = Empresa(
                    id: empresa?.id,
                    nome: nomeController.text.trim(),
                    cnpj: cnpjController.text.trim().isEmpty
                        ? null
                        : cnpjController.text.trim(),
                  );
                  if (empresa == null) {
                    await ApiService.createEmpresa(payload);
                  } else {
                    await ApiService.updateEmpresa(payload);
                  }
                  if (mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (salvo == true) {
      _carregarEmpresas();
    }
  }

  Future<void> _confirmarExclusao(Empresa empresa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar Empresa'),
        content: Text(
          'Deseja desativar "${empresa.nome}"? A empresa não aparecerá mais nas listas ativas, mas seu histórico será mantido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService.deleteEmpresa(empresa.id!);
        _carregarEmpresas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Empresa desativada com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Empresas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Empresa'),
      ),
      body: RefreshIndicator(onRefresh: _carregarEmpresas, child: _buildBody()),
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
                onPressed: _carregarEmpresas,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_empresas.isEmpty) {
      return const Center(child: Text('Nenhuma empresa cadastrada.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: _empresas.length,
      itemBuilder: (context, index) {
        final empresa = _empresas[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.apartment),
            title: Text(empresa.nome),
            subtitle: empresa.cnpj != null ? Text(empresa.cnpj!) : null,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'editar') {
                  _abrirFormulario(empresa);
                } else if (value == 'excluir') {
                  _confirmarExclusao(empresa);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Text('Editar')),
                const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nenhuma empresa encontrada'),
            SizedBox(height: 12),
            Text('Cadastre a primeira empresa no botão "+".'),
          ],
        ),
      ),
    );
  }
}
