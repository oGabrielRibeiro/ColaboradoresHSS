class Empresa {
  final int? id;
  final String nome;
  final String? cnpj;
  final String? contato;
  final DateTime? createdAt;

  Empresa({
    this.id,
    required this.nome,
    this.cnpj,
    this.contato,
    this.createdAt,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'],
      nome: json['nome'],
      cnpj: json['cnpj'],
      contato: json['contato'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cnpj': cnpj,
      'contato': contato,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}