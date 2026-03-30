import 'package:flutter/material.dart';
import 'package:frontend/theme/app_theme.dart';

/// Utilitários para manipulação e exibição de informações de documentos.
class DocumentUtils {
  /// Retorna a cor de status baseada na data de validade de um documento.
  ///
  /// - [AppTheme.danger] para documentos vencidos.
  /// - [AppTheme.warning] para documentos que vencem em 30 dias ou menos.
  /// - [AppTheme.success] para documentos em dia.
  static Color getStatusColor(DateTime validade) {
    final hoje = DateTime.now();
    // Normaliza as datas para ignorar a hora do dia na comparação
    final validadeNormalizada = DateTime(
      validade.year,
      validade.month,
      validade.day,
    );
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);

    if (validadeNormalizada.isBefore(hojeNormalizado)) {
      return AppTheme.danger;
    }
    if (validadeNormalizada.difference(hojeNormalizado).inDays <= 30) {
      return AppTheme.warning;
    }
    return AppTheme.success;
  }

  /// Retorna o texto de status ('Vencido', 'A vencer', 'Em dia')
  /// baseado na data de validade.
  static String getStatusTexto(DateTime validade) {
    final hoje = DateTime.now();
    final validadeNormalizada = DateTime(
      validade.year,
      validade.month,
      validade.day,
    );
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);

    if (validadeNormalizada.isBefore(hojeNormalizado)) {
      return 'Vencido';
    }
    if (validadeNormalizada.difference(hojeNormalizado).inDays <= 30) {
      return 'A vencer';
    }
    return 'Em dia';
  }

  /// Retorna um ícone para um nome de arquivo com base na extensão.
  static IconData getIconForFileName(String fileName) {
    if (fileName.isEmpty) {
      return Icons.insert_drive_file_outlined;
    }

    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}
