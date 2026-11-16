import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Onde o token fica guardado entre uma abertura e outra do app.
abstract class ArmazenamentoSessao {
  Future<String?> ler();
  Future<void> gravar(String? token);
}

/// Guarda o token no navegador/aparelho (shared_preferences).
class ArmazenamentoLocal implements ArmazenamentoSessao {
  static const _chave = 'dashmob.token';

  @override
  Future<String?> ler() async => (await SharedPreferences.getInstance()).getString(_chave);

  @override
  Future<void> gravar(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_chave);
    } else {
      await prefs.setString(_chave, token);
    }
  }
}

/// Só em memória, para os testes.
class ArmazenamentoMemoria implements ArmazenamentoSessao {
  ArmazenamentoMemoria([this._token]);
  String? _token;

  @override
  Future<String?> ler() async => _token;

  @override
  Future<void> gravar(String? token) async => _token = token;
}

/// Token da sessão atual. O [Dio] criado por [criarDio] envia este token em toda chamada
/// e avisa (via [aoExpirar]) quando a API responde 401, para o app voltar ao login.
class SessaoAtual {
  String? token;
  void Function()? aoExpirar;
}

Dio criarDio(SessaoAtual sessao) {
  final dio = Dio(BaseOptions(baseUrl: Config.apiUrl, connectTimeout: const Duration(seconds: 10)));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (opcoes, handler) {
      final t = sessao.token;
      if (t != null && !opcoes.path.endsWith('/login')) opcoes.headers['Authorization'] = 'Bearer $t';
      handler.next(opcoes);
    },
    onError: (erro, handler) {
      if (erro.response?.statusCode == 401 && sessao.token != null && !erro.requestOptions.path.endsWith('/login')) {
        sessao.aoExpirar?.call();
      }
      handler.next(erro);
    },
  ));
  return dio;
}
