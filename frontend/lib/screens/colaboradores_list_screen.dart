import 'package:flutter/material.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_theme.dart';

class ColaboradoresListScreen extends StatefulWidget {
  const ColaboradoresListScreen({super.key});

  @override
  State<ColaboradoresListScreen> createState() =>
      _ColaboradoresListScreenState();
}

class _ColaboradoresListScreenState extends State<ColaboradoresListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = false;

  List<Colaborador> _colaboradores = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarColaboradores();
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
      _carregarMaisColaboradores();
    }
  }

  Future<void> _carregarColaboradores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPage = 1;
      _colaboradores = [];
      _hasMore = true;
    });

    try {
      final response = await ApiService.getColaboradores(page: _currentPage);
      setState(() {
        _colaboradores = response.items;
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

  Future<void> _carregarMaisColaboradores() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final response = await ApiService.getColaboradores(page: _currentPage);
      setState(() {
        _colaboradores.addAll(response.items);
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

  Future<void> _abrirFormulario([Colaborador? colaborador]) async {
    final nomeController = TextEditingController(text: colaborador?.nome ?? '');
    final emailController = TextEditingController(
      text: colaborador?.email ?? '',
    );
    final telefoneController = TextEditingController(
      text: colaborador?.telefone ?? '',
    );
    final formKey = GlobalKey<FormState>();
    bool salvando = false;

    final salvo = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> salvar() async {
            if (!formKey.currentState!.validate()) {
              return;
            }

            setStateDialog(() => salvando = true);

            try {
              final payload = Colaborador(
                id: colaborador?.id,
                nome: nomeController.text.trim(),
                email: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
                telefone: telefoneController.text.trim().isEmpty
                    ? null
                    : telefoneController.text.trim(),
              );

              if (colaborador == null) {
                await ApiService.createColaborador(payload);
              } else {
                await ApiService.updateColaborador(payload);
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
            title: Text(
              colaborador == null ? 'Novo colaborador' : 'Editar colaborador',
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
                          return 'Informe o nome do colaborador';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: telefoneController,
                      decoration: const InputDecoration(labelText: 'Telefone'),
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
    emailController.dispose();
    telefoneController.dispose();

    if (salvo == true) {
      await _carregarColaboradores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              colaborador == null
                  ? 'Colaborador criado com sucesso'
                  : 'Colaborador atualizado com sucesso',
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmarExclusao(Colaborador colaborador) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir colaborador'),
        content: Text(
          'Deseja remover "${colaborador.nome}"? Isso tambem removera vinculos e documentos associados.',
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
      await ApiService.deleteColaborador(colaborador.id!);
      await _carregarColaboradores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Colaborador removido com sucesso')),
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
    final termo = _searchController.text.trim().toLowerCase();
    final colaboradoresFiltrados = _colaboradores.where((colaborador) {
      return colaborador.nome.toLowerCase().contains(termo) ||
          (colaborador.email?.toLowerCase().contains(termo) ?? false) ||
          (colaborador.telefone?.toLowerCase().contains(termo) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Colaboradores'),
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
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo colaborador'),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarColaboradores,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF1EFE5), Color(0xFFE2F4EC)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Base de colaboradores',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acesse o detalhe de cada colaborador para gerenciar documentos e vinculos com empresas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por nome, e-mail ou telefone',
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                2, // Ajustar conforme a largura da tela
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio:
                                1.2, // Ajustar conforme o conteudo
                          ),
                      itemCount: 4, // Mostra 4 esqueletos no grid
                      itemBuilder: (context, index) =>
                          const _ColaboradorSkeletonCard(),
                    )
                  : Column(
                      children: List.generate(
                        5,
                        (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _ColaboradorSkeletonCard(),
                        ),
                      ),
                    )
            else if (_errorMessage.isNotEmpty && _colaboradores.isEmpty)
              Center(child: Text(_errorMessage)) // TODO: Usar _ErrorState
            else if (_colaboradores.isEmpty) // Estado vazio
              const _EmptyState(
                title: 'Nenhum colaborador encontrado',
                message:
                    'Use o botao abaixo para cadastrar o primeiro colaborador.',
              )
            else if (_isGridView) // Visualizacao em Grid (usar GridView.builder diretamente)
              GridView.builder(
                // Usar GridView.builder diretamente
                key: const PageStorageKey('colaboradoresGridView'),
                shrinkWrap:
                    true, // Permite que o GridView se ajuste ao conteudo
                physics:
                    const NeverScrollableScrollPhysics(), // Desabilita o scroll do GridView interno
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Ajustar conforme a largura da tela
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2, // Ajustar conforme o conteudo
                ),
                itemCount:
                    colaboradoresFiltrados.length +
                    (_isLoadingMore
                        ? 1
                        : 0), // Adiciona 1 para o indicador de carregamento
                itemBuilder: (context, index) {
                  if (index == colaboradoresFiltrados.length) {
                    return _buildLoadingMoreIndicator(); // Indicador de carregamento no final
                  }
                  return _ColaboradorGridCard(
                    colaborador: colaboradoresFiltrados[index],
                    onEdit: () =>
                        _abrirFormulario(colaboradoresFiltrados[index]),
                    onDelete: () =>
                        _confirmarExclusao(colaboradoresFiltrados[index]),
                    onTap: () async {
                      context.push(
                        '/dashboard/colaboradores/${colaboradoresFiltrados[index].id}',
                      );
                      await _carregarColaboradores();
                    },
                  );
                },
              )
            else // Visualizacao em Lista (usar ListView.builder diretamente)
              ListView.builder(
                // Usar ListView.builder diretamente
                key: const PageStorageKey('colaboradoresListView'),
                shrinkWrap:
                    true, // Permite que o ListView se ajuste ao conteudo
                physics:
                    const NeverScrollableScrollPhysics(), // Desabilita o scroll do ListView interno
                itemCount:
                    colaboradoresFiltrados.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == colaboradoresFiltrados.length) {
                    return _buildLoadingMoreIndicator();
                  }
                  final colaborador = colaboradoresFiltrados[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryGreen.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: AppTheme.primaryGreen,
                          child: Text(colaborador.nome[0].toUpperCase()),
                        ),
                        title: Text(colaborador.nome),
                        subtitle: Text(
                          colaborador.email?.isNotEmpty == true
                              ? colaborador.email!
                              : colaborador.telefone?.isNotEmpty == true
                              ? colaborador.telefone!
                              : 'Sem contato informado',
                        ),
                        onTap: () async {
                          // Usar GoRouter para navegar para detalhes
                          context.push(
                            '/dashboard/colaboradores/${colaborador.id}',
                          );
                          await _carregarColaboradores();
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'editar') {
                              _abrirFormulario(colaborador);
                            } else if (value == 'excluir') {
                              _confirmarExclusao(colaborador);
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

class _ColaboradorSkeletonCard extends StatelessWidget {
  const _ColaboradorSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Colors.grey.withValues(alpha: 0.2);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(backgroundColor: skeletonColor),
        title: Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 8),
          width: 150,
          height: 12,
          decoration: BoxDecoration(
            color: skeletonColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: skeletonColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ColaboradorGridCard extends StatelessWidget {
  final Colaborador colaborador;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ColaboradorGridCard({
    required this.colaborador,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
                foregroundColor: AppTheme.primaryGreen,
                radius: 28,
                child: Text(
                  colaborador.nome[0].toUpperCase(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                colaborador.nome,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                colaborador.email?.isNotEmpty == true
                    ? colaborador.email!
                    : colaborador.telefone?.isNotEmpty == true
                    ? colaborador.telefone!
                    : 'Sem contato',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') onEdit();
                  if (value == 'excluir') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.more_vert, size: 20),
                ),
              ),
            ],
          ),
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
