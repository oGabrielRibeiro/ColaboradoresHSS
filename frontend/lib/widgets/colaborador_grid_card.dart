import 'package:flutter/material.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:frontend/theme/app_theme.dart';

class ColaboradorGridCard extends StatelessWidget {
  final Colaborador colaborador;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ColaboradorGridCard({
    super.key,
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
                backgroundColor: AppTheme.primaryGreen.withAlpha(30),
                foregroundColor: AppTheme.primaryGreen,
                radius: 28,
                child: Text(
                  colaborador.nome.isNotEmpty
                      ? colaborador.nome[0].toUpperCase()
                      : '?',
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
                colaborador.email ?? colaborador.telefone ?? 'Sem contato',
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
                    color: Colors.grey.withAlpha(25),
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
