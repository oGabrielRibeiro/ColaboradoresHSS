class Vinculo {
  final int id;
  final int colaboradorId;
  final int empresaId;
  final bool ativo;
  final DateTime createdAt;

  Vinculo({
    required this.id,
    required this.colaboradorId,
    required this.empresaId,
    required this.ativo,
    required this.createdAt,
  });

  factory Vinculo.fromJson(Map<String, dynamic> json) {
    return Vinculo(
      id: json['id'],
      colaboradorId: json['colaborador_id'],
      empresaId: json['empresa_id'],
      ativo: json['ativo'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colaborador_id': colaboradorId,
      'empresa_id': empresaId,
      'ativo': ativo,
      'created_at': createdAt.toIso8601String(),
    };
  }
}