class Colaborador {
  final int id;
  final String nome;
  final String? email;
  final String? telefone;
  final DateTime createdAt;

  Colaborador({
    required this.id,
    required this.nome,
    this.email,
    this.telefone,
    required this.createdAt,
  });

  factory Colaborador.fromJson(Map<String, dynamic> json) {
    return Colaborador(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      telefone: json['telefone'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'created_at': createdAt.toIso8601String(),
    };
  }
}