import 'package:dio/dio.dart';

import 'indicadores_repository.dart';
import 'models.dart';

/// Login e cadastro de usuários (US11, US13). As telas usam só esta interface.
abstract class AuthRepository {
  Future<Sessao> login(String email, String senha);

  /// Confere um token guardado e devolve o usuário dele (ou lança ErroApi se venceu).
  Future<Usuario> quemSou();

  Future<List<Usuario>> usuarios();

  Future<Usuario> criarUsuario({required String nome, required String email, required String senha, required Papel papel});

  Future<Usuario> editarUsuario(String id, {String? nome, Papel? papel, bool? ativo, String? senha});
}

class AuthRepositoryHttp implements AuthRepository {
  AuthRepositoryHttp(this._dio);

  final Dio _dio;

  ErroApi _erro(DioException e, String padrao) {
    final detalhe = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
    return ErroApi(detalhe?.toString() ?? '$padrao (${e.message})');
  }

  @override
  Future<Sessao> login(String email, String senha) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/login', data: {'email': email.trim(), 'senha': senha});
      return Sessao.fromJson(r.data!);
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível entrar');
    }
  }

  @override
  Future<Usuario> quemSou() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/me');
      return Usuario.fromJson(r.data!);
    } on DioException catch (e) {
      throw _erro(e, 'Sessão expirada');
    }
  }

  @override
  Future<List<Usuario>> usuarios() async {
    try {
      final r = await _dio.get<List<dynamic>>('/usuarios');
      return r.data!.map((e) => Usuario.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível carregar os usuários');
    }
  }

  @override
  Future<Usuario> criarUsuario({required String nome, required String email, required String senha, required Papel papel}) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/usuarios', data: {'nome': nome, 'email': email.trim(), 'senha': senha, 'papel': papel.valorApi});
      return Usuario.fromJson(r.data!);
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível cadastrar o usuário');
    }
  }

  @override
  Future<Usuario> editarUsuario(String id, {String? nome, Papel? papel, bool? ativo, String? senha}) async {
    try {
      final r = await _dio.put<Map<String, dynamic>>('/usuarios/$id', data: {
        if (nome != null) 'nome': nome,
        if (papel != null) 'papel': papel.valorApi,
        if (ativo != null) 'ativo': ativo,
        if (senha != null && senha.isNotEmpty) 'senha': senha,
      });
      return Usuario.fromJson(r.data!);
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível salvar o usuário');
    }
  }
}
