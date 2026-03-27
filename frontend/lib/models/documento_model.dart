class Documento {
  final int? id;
  final int colaboradorId;
  final int? empresaId;
  final int tipoDocumentoId;
  final String? tipoDocumentoNome;
  final String? tipoDocumentoCategoria;
  final String? empresaNome;
  final String? colaboradorNome;
  final DateTime dataValidade;
  final String? arquivoNome;
  final String? arquivoPath;
  final String? observacoes;
  final bool ativo;
  final int versao;
  final int? substituidoPorId;
  final DateTime? createdAt;

  Documento({
    this.id,
    required this.colaboradorId,
    this.empresaId,
    required this.tipoDocumentoId,
    this.tipoDocumentoNome,
    this.tipoDocumentoCategoria,
    this.empresaNome,
    this.colaboradorNome,
    required this.dataValidade,
    this.arquivoNome,
    this.arquivoPath,
    this.observacoes,
    this.ativo = true,
    this.versao = 1,
    this.substituidoPorId,
    this.createdAt,
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      id: json['id'],
      colaboradorId: json['colaborador_id'],
      empresaId: json['empresa_id'],
      tipoDocumentoId: json['tipo_documento_id'],
      tipoDocumentoNome: json['tipo_documento_nome'],
      tipoDocumentoCategoria: json['tipo_documento_categoria'],
      empresaNome: json['empresa_nome'],
      colaboradorNome: json['colaborador_nome'],
      dataValidade: DateTime.parse(json['data_validade']),
      arquivoNome: json['arquivo_nome'],
      arquivoPath: json['arquivo_path'],
      observacoes: json['observacoes'],
      ativo: json['ativo'] ?? true,
      versao: json['versao'] ?? 1,
      substituidoPorId: json['substituido_por_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colaborador_id': colaboradorId,
      'empresa_id': empresaId,
      'tipo_documento_id': tipoDocumentoId,
      'tipo_documento_nome': tipoDocumentoNome,
      'tipo_documento_categoria': tipoDocumentoCategoria,
      'empresa_nome': empresaNome,
      'colaborador_nome': colaboradorNome,
      'data_validade': dataValidade.toIso8601String(),
      'arquivo_nome': arquivoNome,
      'arquivo_path': arquivoPath,
      'observacoes': observacoes,
      'ativo': ativo,
      'versao': versao,
      'substituido_por_id': substituidoPorId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
