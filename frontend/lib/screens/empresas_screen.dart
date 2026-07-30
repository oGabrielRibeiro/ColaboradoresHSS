import 'package:flutter/material.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:frontend/widgets/error_state_widget.dart';

class EmpresasScreen extends StatefulWidget {
  const EmpresasScreen({super.key});

  @override
  State<EmpresasScreen> createState() => _EmpresasScreenState();
}

class _EmpresasScreenState extends State<EmpresasScreen> {
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
      final response = await ApiService.getEmpresas();
      setState(() {
        _empresas = response.items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _criarEmpresa(String nome) async {
    try {
      final empresa = await ApiService.createEmpresa(Empresa(nome: nome));
      setState(() {
        _empresas.add(empresa);
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    }
  }

  void _abrirModalCriar() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nova Empresa', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        _criarEmpresa(controller.text.trim());
                      }
                    },
                    child: const Text('Criar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empresas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarEmpresas,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? ErrorStateWidget(message: _errorMessage, onRetry: _carregarEmpresas)
          : _empresas.isEmpty
          ? Center(
              child: EmptyStateWidget(
                title: 'Nenhuma empresa cadastrada',
                message: 'Use o botão "+" para cadastrar a primeira empresa.',
                icon: Icons.apartment,
              ),
            )
          : ListView.builder(
              itemCount: _empresas.length,
              itemBuilder: (context, index) {
                final empresa = _empresas[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(empresa.nome),
                    subtitle: empresa.cnpj != null ? Text(empresa.cnpj!) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () {
                        context.push('/dashboard/empresas/${empresa.id}');
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalCriar,
        child: const Icon(Icons.add),
      ),
    );
  }
}
