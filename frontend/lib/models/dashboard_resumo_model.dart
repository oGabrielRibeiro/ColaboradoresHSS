class DashboardResumo {
  final int totalColaboradores;
  final int totalEmpresas;
  final int documentosVencidos;
  final int documentosAVencer;
  final int documentosOK;

  DashboardResumo({
    required this.totalColaboradores,
    required this.totalEmpresas,
    required this.documentosVencidos,
    required this.documentosAVencer,
    required this.documentosOK,
  });

  factory DashboardResumo.fromJson(Map<String, dynamic> json) {
  return DashboardResumo(
    totalColaboradores: json['total_colaboradores'] ?? 0,
    totalEmpresas: json['total_empresas'] ?? 0,
    documentosVencidos: json['documentos_vencidos'] ?? 0,
    documentosAVencer: json['documentos_a_vencer'] ?? 0,
    documentosOK: json['total_documentos_ativos'] ?? 0,
  );
}
}
