class TipoDocumento {
  final int id;
  final String nome;
  final String? descricao;
  final String tipo; // 'pessoal' ou 'empresa'

  TipoDocumento({
    required this.id,
    required this.nome,
    this.descricao,
    required this.tipo,
  });

  factory TipoDocumento.fromJson(Map<String, dynamic> json) {
    return TipoDocumento(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      tipo: json['tipo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'descricao': descricao, 'tipo': tipo};
  }
}
