import 'package:flutter/material.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme/app_theme.dart';
import 'package:frontend/widgets/colaborador_grid_card.dart';
import 'package:frontend/widgets/colaborador_skeleton_card.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:frontend/widgets/error_state_widget.dart';

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
      final response = await ApiService.getColaboradores(
        page: _currentPage,
        search: _searchController.text,
      );
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
      final response = await ApiService.getColaboradores(
        page: _currentPage,
        search: _searchController.text,
      );
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
        title: const Text('Desativar colaborador'),
        content: Text(
          'Deseja desativar "${colaborador.nome}"? O colaborador não aparecerá mais nas listas ativas, mas seus dados e histórico de documentos serão mantidos.',
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

    if (confirmar != true) {
      return;
    }

    try {
      await ApiService.deleteColaborador(colaborador.id!);
      await _carregarColaboradores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Colaborador desativado com sucesso')),
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
                    onChanged: (_) =>
                        _carregarColaboradores(), // Trigger search on change
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por nome, e-mail ou telefone',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildBody(),
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

  Widget _buildBody() {
    if (_isLoading) {
      return _isGridView ? _buildSkeletonGrid() : _buildSkeletonList();
    }

    if (_errorMessage.isNotEmpty && _colaboradores.isEmpty) {
      return ErrorStateWidget(
        message: _errorMessage,
        onRetry: _carregarColaboradores,
      );
    }

    if (_colaboradores.isEmpty) {
      return const EmptyStateWidget(
        title: 'Nenhum colaborador encontrado',
        message: 'Use o botão "Novo colaborador" para cadastrar o primeiro.',
        icon: Icons.people_outline,
      );
    }

    final itemCount = _colaboradores.length + (_isLoadingMore ? 1 : 0);

    if (_isGridView) {
      final screenWidth = MediaQuery.of(context).size.width;
      // Ajusta o número de colunas com base na largura da tela.
      final crossAxisCount = (screenWidth / 300).floor().clamp(2, 5);

      return GridView.builder(
        key: const PageStorageKey('colaboradoresGridView'),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == _colaboradores.length) {
            return _buildLoadingMoreIndicator();
          }
          final colaborador = _colaboradores[index];
          return ColaboradorGridCard(
            colaborador: colaborador,
            onEdit: () => _abrirFormulario(colaborador),
            onDelete: () => _confirmarExclusao(colaborador),
            onTap: () =>
                context.push('/dashboard/colaboradores/${colaborador.id}'),
          );
        },
      );
    }

    return ListView.builder(
      key: const PageStorageKey('colaboradoresListView'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == _colaboradores.length) {
          return _buildLoadingMoreIndicator();
        }
        final colaborador = _colaboradores[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryGreen.withAlpha(30),
                foregroundColor: AppTheme.primaryGreen,
                child: Text(
                  colaborador.nome.isNotEmpty
                      ? colaborador.nome[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(colaborador.nome),
              subtitle: Text(
                colaborador.email ??
                    colaborador.telefone ??
                    'Sem contato informado',
              ),
              onTap: () =>
                  context.push('/dashboard/colaboradores/${colaborador.id}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') _abrirFormulario(colaborador);
                  if (value == 'excluir') _confirmarExclusao(colaborador);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => const ColaboradorSkeletonCard(),
    );
  }

  Widget _buildSkeletonList() {
    return Column(
      children: List.generate(
        5,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ColaboradorSkeletonCard(),
        ),
      ),
    );
  }
}
