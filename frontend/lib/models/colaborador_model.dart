class Colaborador {
  final int? id;
  final String nome;
  final String? email;
  final String? telefone;
  final DateTime? createdAt;

  Colaborador({
    this.id,
    required this.nome,
    this.email,
    this.telefone,
    this.createdAt,
  });

  factory Colaborador.fromJson(Map<String, dynamic> json) {
    return Colaborador(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      telefone: json['telefone'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
