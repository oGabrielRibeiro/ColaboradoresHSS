class Colaborador {
  final int? id;
  final String nome;
  final String? email;
  final String? telefone;
  final String? cpf;
  final String? cargo;
  final DateTime? createdAt;

  Colaborador({
    this.id,
    required this.nome,
    this.email,
    this.telefone,
    this.cpf,
    this.cargo,
    this.createdAt,
  });

  factory Colaborador.fromJson(Map<String, dynamic> json) {
    return Colaborador(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      telefone: json['telefone'],
      cpf: json['cpf'],
      cargo: json['cargo'],
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
      'cpf': cpf,
      'cargo': cargo,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
