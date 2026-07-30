import 'package:flutter/material.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:frontend/models/vinculo_model.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_theme.dart';

class VinculosScreen extends StatefulWidget {
  final Colaborador colaborador;

  const VinculosScreen({super.key, required this.colaborador});

  @override
  State<VinculosScreen> createState() => _VinculosScreenState();
}

class _VinculosScreenState extends State<VinculosScreen> {
  List<Vinculo> _vinculos = [];
  List<Empresa> _empresasDisponiveis = [];
  bool _isLoading = true;
  int? _empresaSelecionadaId;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final vinculos = await ApiService.getVinculos(
        colaboradorId: widget.colaborador.id!,
      );
      final empresasResponse = await ApiService.getEmpresas(limit: 1000);
      final empresas = empresasResponse.items;

      final idsVinculados = vinculos.map((item) => item.empresaId).toSet();
      final disponiveis =
          empresas
              .where((empresa) => !idsVinculados.contains(empresa.id))
              .toList()
            ..sort((a, b) => a.nome.compareTo(b.nome));

      setState(() {
        _vinculos = vinculos;
        _empresasDisponiveis = disponiveis;
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

  Future<void> _vincularEmpresa() async {
    if (_empresaSelecionadaId == null) {
      return;
    }

    try {
      await ApiService.createVinculo(
        Vinculo(
          colaboradorId: widget.colaborador.id!,
          empresaId: _empresaSelecionadaId!,
        ),
      );
      setState(() => _empresaSelecionadaId = null);
      await _carregarDados();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa vinculada com sucesso')),
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

  Future<void> _desvincularEmpresa(Vinculo vinculo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover vinculo'),
        content: Text(
          'Deseja remover o vinculo com "${vinculo.empresaNome ?? 'esta empresa'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    try {
      await ApiService.deleteVinculo(vinculo.id!);
      await _carregarDados();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vinculo removido com sucesso')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vinculos de ${widget.colaborador.nome}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                        'Empresas vinculadas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Somente colaboradores vinculados podem receber documentos empresariais.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        initialValue: _empresaSelecionadaId,
                        decoration: const InputDecoration(
                          labelText: 'Selecionar empresa',
                        ),
                        items: _empresasDisponiveis.map((empresa) {
                          return DropdownMenuItem<int>(
                            value: empresa.id,
                            child: Text(empresa.nome),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _empresaSelecionadaId = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _empresaSelecionadaId == null
                              ? null
                              : _vincularEmpresa,
                          icon: const Icon(Icons.link_rounded),
                          label: const Text('Vincular empresa'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_vinculos.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Nenhuma empresa vinculada no momento'),
                    ),
                  )
                else
                  ..._vinculos.map(
                    (vinculo) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.apartment_rounded,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          title: Text(vinculo.empresaNome ?? 'Empresa'),
                          subtitle: Text(
                            vinculo.empresaCnpj?.isNotEmpty == true
                                ? 'CNPJ: ${vinculo.empresaCnpj}'
                                : 'CNPJ nao informado',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: AppTheme.danger,
                            onPressed: () => _desvincularEmpresa(vinculo),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
