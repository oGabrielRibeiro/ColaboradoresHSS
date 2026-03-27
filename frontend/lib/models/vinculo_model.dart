class Vinculo {
  final int? id;
  final int colaboradorId;
  final int empresaId;
  final String? empresaNome;
  final String? empresaCnpj;
  final bool ativo;
  final DateTime? createdAt;

  Vinculo({
    this.id,
    required this.colaboradorId,
    required this.empresaId,
    this.empresaNome,
    this.empresaCnpj,
    this.ativo = true,
    this.createdAt,
  });

  factory Vinculo.fromJson(Map<String, dynamic> json) {
    return Vinculo(
      id: json['id'],
      colaboradorId: json['colaborador_id'],
      empresaId: json['empresa_id'],
      empresaNome: json['empresa_nome'],
      empresaCnpj: json['empresa_cnpj'],
      ativo: json['ativo'] ?? true,
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
      'empresa_nome': empresaNome,
      'empresa_cnpj': empresaCnpj,
      'ativo': ativo,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
