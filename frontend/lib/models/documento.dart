class Documento {
  final int id;
  final int colaboradorId;
  final int? empresaId; // pode ser nulo se for documento pessoal
  final int tipoDocumentoId;
  final DateTime dataValidade;
  final String? arquivoNome;
  final String? arquivoPath;
  final String? observacoes;
  final bool ativo;
  final int versao;
  final int? substituidoPorId;
  final DateTime createdAt;

  Documento({
    required this.id,
    required this.colaboradorId,
    this.empresaId,
    required this.tipoDocumentoId,
    required this.dataValidade,
    this.arquivoNome,
    this.arquivoPath,
    this.observacoes,
    required this.ativo,
    required this.versao,
    this.substituidoPorId,
    required this.createdAt,
  });

  factory Documento.fromJson(Map<String, dynamic> json) {
    return Documento(
      id: json['id'],
      colaboradorId: json['colaborador_id'],
      empresaId: json['empresa_id'],
      tipoDocumentoId: json['tipo_documento_id'],
      dataValidade: DateTime.parse(json['data_validade']),
      arquivoNome: json['arquivo_nome'],
      arquivoPath: json['arquivo_path'],
      observacoes: json['observacoes'],
      ativo: json['ativo'],
      versao: json['versao'],
      substituidoPorId: json['substituido_por_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colaborador_id': colaboradorId,
      'empresa_id': empresaId,
      'tipo_documento_id': tipoDocumentoId,
      'data_validade': dataValidade.toIso8601String(),
      'arquivo_nome': arquivoNome,
      'arquivo_path': arquivoPath,
      'observacoes': observacoes,
      'ativo': ativo,
      'versao': versao,
      'substituido_por_id': substituidoPorId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
