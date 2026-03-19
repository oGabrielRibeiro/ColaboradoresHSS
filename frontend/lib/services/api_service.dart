import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/models/tipo_documento_model.dart';
import 'package:frontend/models/vinculo_model.dart';
import 'package:frontend/models/dashboard_resumo_model.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000', // URL do backend
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // --- Empresas ---
  static Future<List<Empresa>> getEmpresas() async {
    try {
      final response = await _dio.get('/empresas');
      return (response.data as List)
          .map((json) => Empresa.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar empresas: $e');
    }
  }

  static Future<Empresa> createEmpresa(Empresa empresa) async {
    try {
      final response = await _dio.post('/empresas', data: empresa.toJson());
      return Empresa.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao criar empresa: $e');
    }
  }

  // --- Colaboradores ---
  static Future<List<Colaborador>> getColaboradores() async {
    try {
      final response = await _dio.get('/colaboradores');
      return (response.data as List)
          .map((json) => Colaborador.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar colaboradores: $e');
    }
  }

  static Future<Colaborador> createColaborador(Colaborador colaborador) async {
    try {
      final response = await _dio.post(
        '/colaboradores',
        data: colaborador.toJson(),
      );
      return Colaborador.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao criar colaborador: $e');
    }
  }

  // --- Tipos de Documento ---
  static Future<List<TipoDocumento>> getTiposDocumento() async {
    try {
      final response = await _dio.get('/tipos-documento');
      return (response.data as List)
          .map((json) => TipoDocumento.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar tipos de documento: $e');
    }
  }

  // --- Documentos ---
  static Future<List<Documento>> getDocumentosPorColaborador(
    int colaboradorId,
  ) async {
    try {
      final response = await _dio.get(
        '/documentos',
        queryParameters: {'colaborador_id': colaboradorId},
      );
      return (response.data as List)
          .map((json) => Documento.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar documentos: $e');
    }
  }

  static Future<Documento> createDocumento(Documento documento) async {
    try {
      final response = await _dio.post('/documentos', data: documento.toJson());
      return Documento.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao criar documento: $e');
    }
  }

  // --- Vínculos ---
  static Future<List<Vinculo>> getVinculosPorColaborador(
    int colaboradorId,
  ) async {
    try {
      final response = await _dio.get(
        '/vinculos',
        queryParameters: {'colaborador_id': colaboradorId},
      );
      return (response.data as List)
          .map((json) => Vinculo.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar vínculos: $e');
    }
  }

  static Future<Map<String, int>> getDashboardStats() async {
    try {
      // Busca todos os documentos
      final documentos = await getDocumentos();

      int vencidos = 0;
      int aVencer = 0;
      int dentroPrazo = 0;
      final hoje = DateTime.now();

      for (var doc in documentos) {
        if (doc.dataValidade.isBefore(hoje)) {
          vencidos++;
        } else {
          final diasRestantes = doc.dataValidade.difference(hoje).inDays;
          if (diasRestantes <= 30) {
            aVencer++;
          } else {
            dentroPrazo++;
          }
        }
      }

      return {
        'vencidos': vencidos,
        'aVencer': aVencer,
        'dentroPrazo': dentroPrazo,
      };
    } catch (e) {
      throw Exception('Erro ao carregar estatísticas: $e');
    }
  }

  // Método auxiliar para buscar todos os documentos (sem filtro)
  static Future<List<Documento>> getDocumentos() async {
    try {
      final response = await _dio.get('/documentos');
      return (response.data as List)
          .map((json) => Documento.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar documentos: $e');
    }
  }

  // Métodos para contar colaboradores e empresas
  static Future<int> getTotalColaboradores() async {
    try {
      final response = await _dio.get('/colaboradores');
      return (response.data as List).length;
    } catch (e) {
      throw Exception('Erro ao contar colaboradores: $e');
    }
  }

  static Future<int> getTotalEmpresas() async {
    try {
      final response = await _dio.get('/empresas');
      return (response.data as List).length;
    } catch (e) {
      throw Exception('Erro ao contar empresas: $e');
    }
  }

  static Future<DashboardResumo> getDashboardResumo() async {
    try {
      final response = await _dio.get('/dashboard/resumo');
      return DashboardResumo.fromJson(response.data);
    } catch (e) {
      throw Exception('Erro ao carregar resumo: $e');
    }
  }
}
