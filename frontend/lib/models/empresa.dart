class Empresa {
  final int id;
  final String nome;
  final String? cnpj;
  final String? contato;
  final DateTime createdAt;

  Empresa({
    required this.id,
    required this.nome,
    this.cnpj,
    this.contato,
    required this.createdAt,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'],
      nome: json['nome'],
      cnpj: json['cnpj'],
      contato: json['contato'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cnpj': cnpj,
      'contato': contato,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
