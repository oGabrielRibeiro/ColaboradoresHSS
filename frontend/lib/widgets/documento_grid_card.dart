import 'package:flutter/material.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/widgets/document_utils.dart';
import 'package:intl/intl.dart';

/// Um card em formato de grid para exibir um [Documento].
///
/// Ideal para visualizações mais compactas.
class DocumentoGridCard extends StatelessWidget {
  final Documento documento;
  final VoidCallback? onOpen;

  const DocumentoGridCard({super.key, required this.documento, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final statusColor = DocumentUtils.getStatusColor(documento.dataValidade);
    final statusTexto = DocumentUtils.getStatusTexto(documento.dataValidade);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    DocumentUtils.getIconForFileName(
                      documento.arquivoNome ?? '',
                    ),
                    color: statusColor,
                    size: 24,
                  ),
                  Chip(
                    label: Text(
                      statusTexto,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: statusColor,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                documento.tipoDocumentoNome ?? 'Documento',
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                documento.colaboradorNome ?? 'Colaborador não identificado',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                'Validade: ${DateFormat('dd/MM/yyyy').format(documento.dataValidade)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
