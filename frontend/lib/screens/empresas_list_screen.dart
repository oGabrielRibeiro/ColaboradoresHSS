import 'package:flutter/material.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:go_router/go_router.dart';

class EmpresasListScreen extends StatefulWidget {
  const EmpresasListScreen({super.key});

  @override
  State<EmpresasListScreen> createState() => _EmpresasListScreenState();
}

class _EmpresasListScreenState extends State<EmpresasListScreen> {
  List<Empresa> _empresas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
  }

  Future<void> _carregarEmpresas() async {
    setState(() { _isLoading = true; });
    try {
      final response = await ApiService.getEmpresas(); // Assume que existe
      setState(() { _empresas = response.items; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}'))
      );
      }
    }
  }

  Future<void> _criarEmpresa(String nome) async {
    try {
      final empresa = await ApiService.createEmpresa(nome); // Assume que existe
      setState(() { _empresas.add(empresa); });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}'))
      );
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
              decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
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
          : _empresas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Nenhuma empresa cadastrada.'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _abrirModalCriar,
                        icon: const Icon(Icons.add),
                        label: const Text('Criar Primeira Empresa'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _empresas.length,
                  itemBuilder: (context, index) {
                    final empresa = _empresas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(empresa.nome),
                        subtitle: empresa.cnpj != null ? Text(empresa.cnpj!) : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: () {
                            GoRouter.of(context).push('/dashboard/empresas/${empresa.id}');
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
