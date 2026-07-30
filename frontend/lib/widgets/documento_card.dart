import 'package:flutter/material.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/widgets/document_utils.dart';
import 'package:intl/intl.dart';

/// Um card reutilizável para exibir as informações de um [Documento].
///
/// Mostra o tipo do documento, data de validade, status, versão e outras
/// informações relevantes como colaborador e empresa associados.
class DocumentoCard extends StatelessWidget {
  final Documento documento;
  final VoidCallback? onOpen;
  final VoidCallback? onReplace;
  final VoidCallback? onShowHistory;

  const DocumentoCard({
    super.key,
    required this.documento,
    this.onOpen,
    this.onReplace,
    this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = DocumentUtils.getStatusColor(documento.dataValidade);
    final statusTexto = DocumentUtils.getStatusTexto(documento.dataValidade);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: statusColor,
                  child: const Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documento.tipoDocumentoNome ?? 'Documento sem tipo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Validade: ${DateFormat('dd/MM/yyyy').format(documento.dataValidade)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(statusTexto)),
                if (onShowHistory != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: onShowHistory,
                    tooltip: 'Ver histórico de versões',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Versão ${documento.versao}')),
                if (documento.colaboradorNome != null)
                  Chip(
                    avatar: const Icon(Icons.person_outline, size: 16),
                    label: Text(documento.colaboradorNome!),
                  ),
                if (documento.empresaNome != null)
                  Chip(
                    avatar: const Icon(
                      Icons.business_center_outlined,
                      size: 16,
                    ),
                    label: Text(documento.empresaNome!),
                  ),
              ],
            ),
            if (documento.arquivoPath != null && onOpen != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir anexo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onReplace != null)
                    ElevatedButton.icon(
                      onPressed: onReplace,
                      icon: const Icon(Icons.swap_vert),
                      label: Text('Substituir (v${documento.versao})'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
