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
      totalColaboradores: json['totalColaboradores'] ?? 0,
      totalEmpresas: json['totalEmpresas'] ?? 0,
      documentosVencidos: json['documentosVencidos'] ?? 0,
      documentosAVencer: json['documentosAVencer'] ?? 0,
      documentosOK: json['documentosOK'] ?? 0,
    );
  }
}
