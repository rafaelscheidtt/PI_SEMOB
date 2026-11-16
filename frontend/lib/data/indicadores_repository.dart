import 'package:dio/dio.dart';

import '../core/config.dart';
import '../core/formatos.dart';
import '../core/periodo.dart';
import 'models.dart';

/// Acesso aos dados. As telas usam só esta interface, assim os testes passam um repositório falso.
abstract class IndicadoresRepository {
  Future<Indicadores> obter({
    required DateTime inicio,
    required DateTime fim,
    required Granularidade granularidade,
    String? linha,
    bool comparar = false,
  });

  Future<List<Linha>> linhas();

  Future<List<ResumoLinha>> resumoPorLinha({required DateTime inicio, required DateTime fim});

  Future<List<Ocorrencia>> ocorrencias({required DateTime inicio, required DateTime fim, String? linha, TipoOcorrencia? tipo});

  Future<DetalhesOperacao> detalhes({required DateTime inicio, required DateTime fim, String? linha});

  Future<Financeiro> financeiro({required DateTime inicio, required DateTime fim, required Granularidade granularidade, bool comparar = false});

  Future<Alertas> alertas({required DateTime inicio, required DateTime fim, String? linha});

  Future<List<Importacao>> importacoes();

  Future<ResultadoImportacao> importar(List<ArquivoEnvio> arquivos);
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

  Map<String, dynamic> _periodo(DateTime inicio, DateTime fim, [String? linha]) => {
        'inicio': fmtDataApi(inicio),
        'fim': fmtDataApi(fim),
        if (linha != null && linha.isNotEmpty) 'linha': linha,
      };

  ErroApi _erro(DioException e, String padrao) {
    final detalhe = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
    return ErroApi(detalhe?.toString() ?? '$padrao (${e.message})');
  }

  @override
  Future<Indicadores> obter({
    required DateTime inicio,
    required DateTime fim,
    required Granularidade granularidade,
    String? linha,
    bool comparar = false,
  }) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/indicadores', queryParameters: {
        ..._periodo(inicio, fim, linha),
        'granularidade': granularidade.valorApi,
        if (comparar) 'comparar': 'true',
      });
      return Indicadores.fromJson(r.data!);
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível consultar a API');
    }
  }

  @override
  Future<List<Linha>> linhas() async {
    try {
      final r = await _dio.get<List<dynamic>>('/linhas');
      return r.data!.map((e) => Linha.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível carregar as linhas');
    }
  }

  @override
  Future<List<ResumoLinha>> resumoPorLinha({required DateTime inicio, required DateTime fim}) async {
    try {
      final r = await _dio.get<List<dynamic>>('/indicadores/linhas', queryParameters: _periodo(inicio, fim));
      return r.data!.map((e) => ResumoLinha.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível carregar o resumo por linha');
    }
  }

  @override
  Future<List<Ocorrencia>> ocorrencias({required DateTime inicio, required DateTime fim, String? linha, TipoOcorrencia? tipo}) async {
    try {
      final r = await _dio.get<List<dynamic>>('/ocorrencias', queryParameters: {
        ..._periodo(inicio, fim, linha),
        if (tipo != null) 'tipo': tipo.valorApi,
      });
      return r.data!.map((e) => Ocorrencia.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível carregar as ocorrências');
    }
  }

  @override
  Future<DetalhesOperacao> detalhes({required DateTime inicio, required DateTime fim, String? linha}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/indicadores/detalhes', queryParameters: _periodo(inicio, fim, linha));
      return DetalhesOperacao.fromJson(r.data!);
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível carregar o detalhamento');
    }
  }

  @override
  Future<Financeiro> financeiro({required DateTime inicio, required DateTime fim, required Granularidade granularidade, bool comparar = false}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/indicadores/financeiro', queryParameters: {
        ..._periodo(inicio, fim),
        'granularidade': granularidade.valorApi,
        if (comparar) 'comparar': 'true',
      });
      return Financeiro.fromJson(r.data!);
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível carregar o financeiro');
    }
  }

  @override
  Future<Alertas> alertas({required DateTime inicio, required DateTime fim, String? linha}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/alertas', queryParameters: _periodo(inicio, fim, linha));
      return Alertas.fromJson(r.data!);
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível carregar os alertas');
    }
  }

  @override
  Future<List<Importacao>> importacoes() async {
    try {
      final r = await _dio.get<List<dynamic>>('/importacoes');
      return r.data!.map((e) => Importacao.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível carregar o histórico de importações');
    }
  }

  @override
  Future<ResultadoImportacao> importar(List<ArquivoEnvio> arquivos) async {
    final form = FormData();
    for (final a in arquivos) {
      form.files.add(MapEntry('arquivos', MultipartFile.fromBytes(a.bytes, filename: a.nome)));
    }
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/importacoes',
        data: form,
        options: Options(sendTimeout: const Duration(minutes: 5), receiveTimeout: const Duration(minutes: 5)),
      );
      return ResultadoImportacao.fromJson(r.data!);
    } on DioException catch (e) {
      throw _erro(e, 'Não foi possível importar os arquivos');
    }
  }
}
