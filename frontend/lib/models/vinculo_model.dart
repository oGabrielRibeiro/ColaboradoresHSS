class Vinculo {
  final int? id;
  final int colaboradorId;
  final int empresaId;
  final bool ativo;
  final DateTime? createdAt;

  Vinculo({
    this.id,
    required this.colaboradorId,
    required this.empresaId,
    this.ativo = true,
    this.createdAt,
  });

  factory Vinculo.fromJson(Map<String, dynamic> json) {
    return Vinculo(
      id: json['id'],
      colaboradorId: json['colaborador_id'],
      empresaId: json['empresa_id'],
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
      'ativo': ativo,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}