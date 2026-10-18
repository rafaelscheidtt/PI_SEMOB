import 'package:dio/dio.dart';

import '../core/config.dart';
import '../core/formatos.dart';
import '../core/periodo.dart';
import 'models.dart';

/// Acesso aos dados. A tela usa só esta interface, assim os testes passam um repositório falso.
abstract class IndicadoresRepository {
  Future<Indicadores> obter({
    required DateTime inicio,
    required DateTime fim,
    required Granularidade granularidade,
    String? linha,
  });

  Future<List<Linha>> linhas();
}

class ErroApi implements Exception {
  ErroApi(this.mensagem);
  final String mensagem;
  @override
  String toString() => mensagem;
}

class IndicadoresRepositoryHttp implements IndicadoresRepository {
  IndicadoresRepositoryHttp({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: Config.apiUrl, connectTimeout: const Duration(seconds: 10)));

  final Dio _dio;

  @override
  Future<Indicadores> obter({
    required DateTime inicio,
    required DateTime fim,
    required Granularidade granularidade,
    String? linha,
  }) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/indicadores', queryParameters: {
        'inicio': fmtDataApi(inicio),
        'fim': fmtDataApi(fim),
        'granularidade': granularidade.valorApi,
        if (linha != null && linha.isNotEmpty) 'linha': linha,
      });
      return Indicadores.fromJson(r.data!);
    } on DioException catch (e) {
      final detalhe = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
      throw ErroApi(detalhe?.toString() ?? 'Não foi possível consultar a API (${e.message})');
    }
  }

  @override
  Future<List<Linha>> linhas() async {
    try {
      final r = await _dio.get<List<dynamic>>('/linhas');
      return r.data!.map((e) => Linha.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ErroApi('Não foi possível carregar as linhas (${e.message})');
    }
  }
}
