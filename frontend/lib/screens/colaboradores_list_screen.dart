import 'package:flutter/material.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/screens/colaborador_detail_screen.dart';

class ColaboradoresListScreen extends StatefulWidget {
  const ColaboradoresListScreen({super.key});

  @override
  State<ColaboradoresListScreen> createState() => _ColaboradoresListScreenState();
}

class _ColaboradoresListScreenState extends State<ColaboradoresListScreen> {
  List<Colaborador> _colaboradores = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarColaboradores();
  }

  Future<void> _carregarColaboradores() async {
    setState(() => _isLoading = true);
    try {
      final colaboradores = await ApiService.getColaboradores();
      setState(() {
        _colaboradores = colaboradores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar colaboradores: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colaboradores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Futuramente: tela de cadastro
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _colaboradores.isEmpty
                  ? const Center(child: Text('Nenhum colaborador cadastrado'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _colaboradores.length,
                      itemBuilder: (context, index) {
                        final colab = _colaboradores[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryGreen,
                              child: Text(
                                colab.nome[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(colab.nome),
                            subtitle: Text(colab.email ?? 'Sem e-mail'),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ColaboradorDetailScreen(
                                    colaborador: colab,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}