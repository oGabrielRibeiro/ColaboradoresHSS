class Vinculo {
  final int? id;
  final int colaboradorId;
  final String? colaboradorNome;
  final int empresaId;
  final String? empresaNome;
  final String? empresaCnpj;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final bool? ativo;
  final DateTime? createdAt;

  Vinculo({
    this.id,
    required this.colaboradorId,
    this.colaboradorNome,
    required this.empresaId,
    this.empresaNome,
    this.empresaCnpj,
    this.dataInicio,
    this.dataFim,
    this.ativo,
    this.createdAt,
  });

  factory Vinculo.fromJson(Map<String, dynamic> json) {
    // Helper para fazer o parse de datas que podem ser nulas
    DateTime? parseDate(String? dateString) {
      return dateString != null ? DateTime.parse(dateString) : null;
    }

    return Vinculo(
      id: json['id'],
      colaboradorId: json['colaborador_id'],
      colaboradorNome: json['colaborador_nome'],
      empresaId: json['empresa_id'],
      empresaNome: json['empresa_nome'],
      empresaCnpj: json['empresa_cnpj'],
      dataInicio: parseDate(json['data_inicio']),
      dataFim: parseDate(json['data_fim']),
      ativo: json['ativo'],
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colaborador_id': colaboradorId,
      'empresa_id': empresaId,
    };
  }
}
