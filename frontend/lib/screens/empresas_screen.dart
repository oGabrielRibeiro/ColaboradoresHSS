import 'package:flutter/material.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_theme.dart';

class EmpresasScreen extends StatefulWidget {
  const EmpresasScreen({super.key});

  @override
  State<EmpresasScreen> createState() => _EmpresasScreenState();
}

class _EmpresasScreenState extends State<EmpresasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = false;

  List<Empresa> _empresas = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.95 &&
        !_isLoadingMore) {
      _carregarMaisEmpresas();
    }
  }

  Future<void> _carregarEmpresas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 1;
      _empresas = [];
      _hasMore = true;
    });

    try {
      final response = await ApiService.getEmpresas(
        page: _currentPage,
        search: _searchController.text,
      );
      setState(() {
        _empresas = response.items;
        _hasMore = response.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _carregarMaisEmpresas() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final response = await ApiService.getEmpresas(
        page: _currentPage,
        search: _searchController.text,
      );
      setState(() {
        _empresas.addAll(response.items);
        _hasMore = response.hasMore;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _abrirFormulario([Empresa? empresa]) async {
    final nomeController = TextEditingController(text: empresa?.nome ?? '');
    final cnpjController = TextEditingController(text: empresa?.cnpj ?? '');
    final contatoController = TextEditingController(
      text: empresa?.contato ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool salvando = false;

    final salvo = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> salvar() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setStateDialog(() => salvando = true);
              try {
                final payload = Empresa(
                  id: empresa?.id,
                  nome: nomeController.text.trim(),
                  cnpj: cnpjController.text.trim().isEmpty
                      ? null
                      : cnpjController.text.trim(),
                  contato: contatoController.text.trim().isEmpty
                      ? null
                      : contatoController.text.trim(),
                );

                if (empresa == null) {
                  await ApiService.createEmpresa(payload);
                } else {
                  await ApiService.updateEmpresa(payload);
                }

                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context, true);
              } catch (e) {
                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                );
                setStateDialog(() => salvando = false);
              }
            }

            return AlertDialog(
              title: Text(empresa == null ? 'Nova empresa' : 'Editar empresa'),
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
                            return 'Informe o nome da empresa';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cnpjController,
                        decoration: const InputDecoration(labelText: 'CNPJ'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contatoController,
                        decoration: const InputDecoration(labelText: 'Contato'),
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
        );
      },
    );

    nomeController.dispose();
    cnpjController.dispose();
    contatoController.dispose();

    if (salvo == true) {
      await _carregarEmpresas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              empresa == null
                  ? 'Empresa criada com sucesso'
                  : 'Empresa atualizada com sucesso',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmarExclusao(Empresa empresa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir empresa'),
        content: Text(
          'Deseja remover "${empresa.nome}"? Essa acao nao pode ser desfeita.',
        ),
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

    if (confirmar != true) {
      return;
    }

    try {
      await ApiService.deleteEmpresa(empresa.id!);
      await _carregarEmpresas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empresa excluida com sucesso')),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardsCrossAxisCount = width > 1100
        ? 3
        : width > 700
        ? 2
        : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empresas'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // TODO: Mover para um widget de acoes rapidas
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nova empresa'),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarEmpresas,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6F4EF), Color(0xFFE7EEFF)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cadastro e manutencao de empresas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use essa tela para criar, editar e revisar os dados das empresas vinculadas aos colaboradores.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) =>
                        _carregarEmpresas(), // Trigger search on change
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por nome, CNPJ ou contato',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              _isGridView
                  ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cardsCrossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) =>
                          const _EmpresaSkeletonCard(),
                    )
                  : Column(
                      children: List.generate(
                        4,
                        (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _EmpresaSkeletonCard(),
                        ),
                      ),
                    )
            else if (_errorMessage.isNotEmpty && _empresas.isEmpty)
              _ErrorState(message: _errorMessage, onRetry: _carregarEmpresas)
            else if (_empresas.isEmpty) // Estado vazio
              const _EmptyState(
                title: 'Nenhuma empresa encontrada',
                message:
                    'Cadastre uma empresa para comecar os vinculos e documentos empresariais.',
              )
            else if (_isGridView) // Visualizacao em Grid
              GridView.builder(
                // Usar GridView.builder diretamente
                key: const PageStorageKey('empresasGridView'),
                shrinkWrap:
                    true, // Permite que o GridView se ajuste ao conteudo
                physics:
                    const NeverScrollableScrollPhysics(), // Desabilita o scroll do GridView interno
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cardsCrossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5, // Ajuste para o tamanho do card
                ),
                itemCount:
                    _empresas.length +
                    (_isLoadingMore
                        ? 1
                        : 0), // Adiciona 1 para o indicador de carregamento
                itemBuilder: (context, index) {
                  if (index == _empresas.length) {
                    return _buildLoadingMoreIndicator(); // Indicador de carregamento no final
                  }
                  return _EmpresaGridCard(
                    empresa: _empresas[index],
                    onEdit: () => _abrirFormulario(_empresas[index]),
                    onDelete: () => _confirmarExclusao(_empresas[index]),
                    onTap: () => context.push(
                      '/dashboard/empresas/${_empresas[index].id}',
                    ),
                  );
                },
              )
            else // Visualizacao em Lista (usar ListView.builder diretamente)
              ListView.builder(
                // Usar ListView.builder diretamente
                key: const PageStorageKey('empresasListView'),
                shrinkWrap:
                    true, // Permite que o ListView se ajuste ao conteudo
                physics:
                    const NeverScrollableScrollPhysics(), // Desabilita o scroll do ListView interno
                itemCount: _empresas.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _empresas.length) {
                    return _buildLoadingMoreIndicator();
                  }
                  final empresa = _empresas[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            context.push('/dashboard/empresas/${empresa.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.apartment_rounded,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      empresa.nome,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      empresa.cnpj?.isNotEmpty == true
                                          ? 'CNPJ: ${empresa.cnpj}'
                                          : 'CNPJ nao informado',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Text(
                                      empresa.contato?.isNotEmpty == true
                                          ? 'Contato: ${empresa.contato}'
                                          : 'Contato nao informado',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'editar') {
                                    _abrirFormulario(empresa);
                                  } else if (value == 'excluir') {
                                    _confirmarExclusao(empresa);
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmpresaSkeletonCard extends StatelessWidget {
  const _EmpresaSkeletonCard();

  @override
  Widget build(BuildContext context) {
    // Usamos cores com opacidade para simular o efeito de carregamento visual
    final skeletonColor = Colors.grey.withValues(alpha: 0.2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: skeletonColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmpresaGridCard extends StatelessWidget {
  final Empresa empresa;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _EmpresaGridCard({
    required this.empresa,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'editar') onEdit();
                      if (value == 'excluir') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                empresa.nome,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                empresa.cnpj?.isNotEmpty == true
                    ? 'CNPJ: ${empresa.cnpj}'
                    : 'CNPJ nao informado',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                empresa.contato?.isNotEmpty == true
                    ? 'Contato: ${empresa.contato}'
                    : 'Contato nao informado',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
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
  final String title;
  final String message;

  const _EmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 42,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
