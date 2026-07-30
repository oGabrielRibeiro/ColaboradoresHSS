import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/colaborador_model.dart';
import 'package:frontend/models/dashboard_resumo_model.dart';
import 'package:frontend/models/documento_model.dart';
import 'package:frontend/models/paginated_response.dart';
import 'package:frontend/models/empresa_model.dart';
import 'package:frontend/models/tipo_documento_model.dart';
import 'package:frontend/models/vinculo_model.dart';

class ApiService {
  static const String _tokenStorageKey = 'auth_token';
  static Map<String, dynamic>? _usuarioAtual;
  static String? _token;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static String _resolveBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
  }

  static String get baseUrl => _dio.options.baseUrl;
  static bool get isAuthenticated => _token != null;
  static Map<String, dynamic>? get usuarioAtual => _usuarioAtual;

  static Future<void> initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    final persistedToken = prefs.getString(_tokenStorageKey);
    if (persistedToken == null || persistedToken.isEmpty) {
      return;
    }

    _token = persistedToken;
    _dio.options.headers['Authorization'] = 'Bearer $_token';

    try {
      final me = await getAuthMe();
      _usuarioAtual = me;
    } catch (_) {
      await logout();
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'senha': senha},
      );

      final data = Map<String, dynamic>.from(response.data);
      final token = data['token'] as String?;
      final usuario = data['usuario'] as Map<String, dynamic>?;

      if (token == null || usuario == null) {
        throw Exception('Resposta de autenticacao invalida');
      }

      _token = token;
      _usuarioAtual = usuario;
      _dio.options.headers['Authorization'] = 'Bearer $_token';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenStorageKey, token);

      return usuario;
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao autenticar usuario'));
    }
  }

  static Future<void> logout() async {
    _token = null;
    _usuarioAtual = null;
    _dio.options.headers.remove('Authorization');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenStorageKey);
  }

  static Future<Map<String, dynamic>> getAuthMe() async {
    try {
      final response = await _dio.get('/auth/me');
      final data = Map<String, dynamic>.from(response.data);
      final usuario = Map<String, dynamic>.from(data['usuario'] as Map);
      _usuarioAtual = usuario;
      return usuario;
    } catch (e) {
      throw Exception(_extractError(e, 'Sessao invalida'));
    }
  }

  static Future<List<Vinculo>> getVinculos({
    int? colaboradorId,
    int? empresaId,
  }) async {
    try {
      final response = await _dio.get(
        '/vinculos',
        queryParameters: {
          if (colaboradorId != null) 'colaborador_id': colaboradorId,
          if (empresaId != null) 'empresa_id': empresaId,
        },
      );
      return (response.data as List)
          .map((json) => Vinculo.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(_extractError(e, 'Falha ao carregar vínculos'));
    }
  }

  static Future<String> getSignedFileUrl(String arquivoPath) async {
    try {
      final response = await _dio.get(
        '/arquivos/link',
        queryParameters: {'path': arquivoPath},
      );
      final data = Map<String, dynamic>.from(response.data);
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Link de arquivo invalido');
      }
      return url;
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao gerar link do arquivo'));
    }
  }

  static String _extractError(Object error, String fallbackMessage) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic> &&
          responseData['error'] is String) {
        return responseData['error'] as String;
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    return fallbackMessage;
  }

  static Future<PaginatedResponse<Empresa>> getEmpresas({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        '/empresas',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null) 'search': search,
        },
      );
      final items = (response.data as List)
          .map((json) => Empresa.fromJson(json))
          .toList();
      final totalCount =
          int.tryParse(response.headers.value('x-total-count') ?? '0') ?? 0;

      final hasMore = page * limit < totalCount;
      return PaginatedResponse(
        items: items,
        totalCount: totalCount,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao carregar empresas'));
    }
  }

  static Future<Empresa> createEmpresa(Empresa empresa) async {
    try {
      final response = await _dio.post('/empresas', data: empresa.toJson());
      return Empresa.fromJson(response.data);
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao criar empresa'));
    }
  }

  static Future<Empresa> updateEmpresa(Empresa empresa) async {
    try {
      final response = await _dio.put(
        '/empresas/${empresa.id}',
        data: empresa.toJson(),
      );
      return Empresa.fromJson(response.data);
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao atualizar empresa'));
    }
  }

  static Future<Empresa> getEmpresaById(int id) async {
    try {
      final response = await _dio.get('/empresas/$id');
      return Empresa.fromJson(response.data);
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao carregar empresa'));
    }
  }

  static Future<void> deleteEmpresa(int id) async {
    try {
      // Alterado para soft delete (desativação)
      await _dio.put('/empresas/$id/desativar');
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao remover empresa'));
    }
  }

  static Future<PaginatedResponse<Colaborador>> getColaboradores({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        '/colaboradores',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null) 'search': search,
        },
      );
      final items = (response.data as List)
          .map((json) => Colaborador.fromJson(json))
          .toList();
      final totalCount =
          int.tryParse(response.headers.value('x-total-count') ?? '0') ?? 0;

      final hasMore = page * limit < totalCount;
      return PaginatedResponse(
        items: items,
        totalCount: totalCount,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao carregar colaboradores'));
    }
  }

  static Future<Colaborador> getColaboradorById(int id) async {
    try {
      final response = await _dio.get('/colaboradores/$id');
      return Colaborador.fromJson(response.data);
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao carregar colaborador'));
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
      throw Exception(_extractError(e, 'Erro ao criar colaborador'));
    }
  }

  static Future<Colaborador> updateColaborador(Colaborador colaborador) async {
    try {
      final response = await _dio.put(
        '/colaboradores/${colaborador.id}',
        data: colaborador.toJson(),
      );
      return Colaborador.fromJson(response.data);
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao atualizar colaborador'));
    }
  }

  static Future<void> deleteColaborador(int id) async {
    try {
      // Alterado para soft delete (desativação)
      await _dio.put('/colaboradores/$id/desativar');
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao remover colaborador'));
    }
  }

  static Future<List<TipoDocumento>> getTiposDocumento() async {
    try {
      final response = await _dio.get('/tipos-documento');
      return (response.data as List)
          .map((json) => TipoDocumento.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao carregar tipos de documento'));
    }
  }

  static Future<TipoDocumento> createTipoDocumento({
    required String nome,
    required String tipo,
    String? descricao,
  }) async {
    try {
      final response = await _dio.post(
        '/tipos-documento',
        data: {'nome': nome, 'tipo': tipo, 'descricao': descricao},
      );
      return TipoDocumento.fromJson(response.data);
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao criar tipo de documento'));
    }
  }

  static Future<TipoDocumento> updateTipoDocumento({
    required int id,
    required String nome,
    required String tipo,
    String? descricao,
  }) async {
    try {
      final response = await _dio.put(
        '/tipos-documento/$id',
        data: {'nome': nome, 'tipo': tipo, 'descricao': descricao},
      );
      return TipoDocumento.fromJson(response.data);
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao atualizar tipo de documento'));
    }
  }

  static Future<void> deleteTipoDocumento(int id) async {
    try {
      await _dio.delete('/tipos-documento/$id');
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao remover tipo de documento'));
    }
  }

  static Future<PaginatedResponse<Documento>> getDocumentos({
    int? colaboradorId,
    int? empresaId,
    String? status,
    bool somenteAtivos = true,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/documentos',
        queryParameters: {
          if (colaboradorId != null) 'colaborador_id': colaboradorId,
          if (empresaId != null) 'empresa_id': empresaId,
          if (status != null) 'status': status,
          'ativo': somenteAtivos,
          'page': page,
          'limit': limit,
        },
      );

      final items = (response.data as List)
          .map((json) => Documento.fromJson(json))
          .toList();
      final totalCount =
          int.tryParse(response.headers.value('x-total-count') ?? '0') ?? 0;

      final hasMore = page * limit < totalCount;
      return PaginatedResponse(
        items: items,
        totalCount: totalCount,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao carregar documentos'));
    }
  }

  static Future<Documento> createDocumento(Documento documento) async {
    try {
      final response = await _dio.post('/documentos', data: documento.toJson());
      return Documento.fromJson(response.data);
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao criar documento'));
    }
  }

  static Future<List<Documento>> getHistoricoDocumento(int documentoId) async {
    try {
      final response = await _dio.get('/documentos/$documentoId/historico');
      return (response.data as List)
          .map((json) => Documento.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception(
        _extractError(e, 'Erro ao carregar historico do documento'),
      );
    }
  }

  static Future<Vinculo> createVinculo(Vinculo vinculo) async {
    try {
      final response = await _dio.post('/vinculos', data: vinculo.toJson());
      return Vinculo.fromJson(response.data);
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao criar vinculo'));
    }
  }

  static Future<void> deleteVinculo(int id) async {
    try {
      await _dio.delete('/vinculos/$id');
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao remover vinculo'));
    }
  }

  static Future<void> atualizarVinculos(
    int colaboradorId,
    List<int> novosIdsEmpresa,
  ) async {
    try {
      // Esta é uma implementação simples. O ideal seria uma rota de "sync" no backend.
      // 1. Pega os vínculos atuais
      final vinculosAtuais = await getVinculos(colaboradorId: colaboradorId);

      // 2. Remove todos os vínculos existentes para este colaborador
      for (final vinculo in vinculosAtuais) {
        if (vinculo.id != null) {
          await deleteVinculo(vinculo.id!);
        }
      }

      // 3. Cria os novos vínculos
      for (final empresaId in novosIdsEmpresa) {
        await createVinculo(
          Vinculo(colaboradorId: colaboradorId, empresaId: empresaId),
        );
      }
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao atualizar vínculos'));
    }
  }

  static Future<DashboardResumo> getDashboardResumo() async {
    try {
      final response = await _dio.get('/dashboard/resumo');

      return DashboardResumo.fromJson(response.data);
    } catch (e) {
      throw Exception(_extractError(e, 'Erro ao carregar resumo'));
    }
  }

  static Future<Map<String, dynamic>> uploadArquivo(
    FilePickerResult arquivo, {
    int? documentoId,
    String? novaValidade, // This is data_validade
    String? observacoes,
  }) async {
    try {
      final file = arquivo.files.single;
      late MultipartFile multipartFile;

      if (kIsWeb && file.bytes != null) {
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        );
      } else {
        multipartFile = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        );
      }

      final formData = FormData.fromMap({
        'arquivo': multipartFile,
        if (novaValidade != null) 'data_validade': novaValidade,
        if (observacoes != null) 'observacoes': observacoes,
      });

      final response = await _dio.post(
        documentoId != null ? '/documentos/$documentoId/substituir' : '/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = Map<String, dynamic>.from(response.data);
      final uploadFileData = data['file'];

      if (uploadFileData is Map) {
        final fileMap = Map<String, dynamic>.from(uploadFileData);
        return {
          ...data,
          'arquivo_nome':
              fileMap['originalname'] ??
              fileMap['filename'] ??
              data['arquivo_nome'],
          'arquivo_path': fileMap['path'] ?? data['arquivo_path'],
        };
      }

      return data;
    } catch (e) {
      throw Exception(_extractError(e, 'Erro no upload do arquivo'));
    }
  }
}
