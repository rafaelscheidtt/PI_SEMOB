// apoio dos testes de widget: repositório falso, dados de exemplo e a montagem do app
import 'package:dashmob/core/filtros.dart';
import 'package:dashmob/core/periodo.dart';
import 'package:dashmob/core/sessao.dart';
import 'package:dashmob/data/auth_repository.dart';
import 'package:dashmob/data/indicadores_repository.dart';
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/painel/painel_shell.dart';
import 'package:dashmob/features/painel/telas.dart';
import 'package:dashmob/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class RepositorioFalso implements IndicadoresRepository {
  RepositorioFalso(this.resposta, {this.historico = const [], this.resultadoImportacao});
  final Indicadores resposta;
  final List<Importacao> historico;
  final ResultadoImportacao? resultadoImportacao;
  List<ArquivoEnvio>? arquivosEnviados;
  Granularidade? ultimaGranularidade;
  String? ultimaLinha;
  bool? ultimoComparar;
  int consultas = 0;

  @override
  Future<Indicadores> obter({required DateTime inicio, required DateTime fim, required Granularidade granularidade, String? linha, bool comparar = false}) async {
    consultas++;
    ultimaGranularidade = granularidade;
    ultimaLinha = linha;
    ultimoComparar = comparar;
    return resposta;
  }

  @override
  Future<List<Linha>> linhas() async => const [Linha(codigo: '01', nome: 'B. Santa Maria'), Linha(codigo: '02', nome: 'Circular Gerty')];

  @override
  Future<List<ResumoLinha>> resumoPorLinha({required DateTime inicio, required DateTime fim}) async => const [
        ResumoLinha(codigo: '01', nome: 'B. Santa Maria', kmTotal: 700, viagens: 60, diasComDados: 1, naoRealizadas: 2),
        ResumoLinha(codigo: '02', nome: 'Circular Gerty', kmTotal: 500.5, viagens: 40, diasComDados: 1, naoIniciadas: 1),
      ];

  @override
  Future<List<Ocorrencia>> ocorrencias({required DateTime inicio, required DateTime fim, String? linha, TipoOcorrencia? tipo}) async => linha != '02'
      ? const []
      : [
          Ocorrencia(tipo: TipoOcorrencia.naoRealizada, data: DateTime(2026, 9, 3), linha: '02', atendimento: 'Circular Gerty Sentido Ida', sentido: 'I', tabela: '3A', inicioProgramado: DateTime(2026, 9, 3, 6, 20), fimProgramado: DateTime(2026, 9, 3, 6, 53)),
          Ocorrencia(tipo: TipoOcorrencia.naoTerminada, data: DateTime(2026, 9, 7), linha: '02', atendimento: 'Circular Gerty Sentido Volta', sentido: 'V', tabela: '7B', inicioProgramado: DateTime(2026, 9, 7, 22, 0), inicioRealizado: DateTime(2026, 9, 7, 22, 1)),
        ];

  @override
  Future<DetalhesOperacao> detalhes({required DateTime inicio, required DateTime fim, String? linha}) async => DetalhesOperacao(
        linha: linha,
        turnos: linha != null ? const [] : const [Turno(turno: 'manha', programadas: 50, realizadas: 49, fcv: 98), Turno(turno: 'tarde', programadas: 52, realizadas: 51, fcv: 98.08)],
        faixasHorarias: const [FaixaHoraria(faixa: 5, viagens: 10), FaixaHoraria(faixa: 6, viagens: 30), FaixaHoraria(faixa: 7, viagens: 20)],
      );

  @override
  Future<List<Importacao>> importacoes() async => historico;

  @override
  Future<ResultadoImportacao> importar(List<ArquivoEnvio> arquivos) async {
    arquivosEnviados = arquivos;
    final r = resultadoImportacao;
    if (r == null) throw ErroApi('Não foi possível importar os arquivos');
    return r;
  }
}

/// Usuários de teste, um por papel (US11).
const admin = Usuario(id: 'u1', nome: 'Ana Admin', email: 'admin@semob.teste', papel: Papel.administrador);
const gestor = Usuario(id: 'u2', nome: 'Gil Gestor', email: 'gestor@semob.teste', papel: Papel.gestor);
const executivo = Usuario(id: 'u3', nome: 'Eva Executiva', email: 'exec@semob.teste', papel: Papel.executivo);

/// Login e cadastro falsos: aceita a senha "senha123" de qualquer usuário da lista.
class AuthFalso implements AuthRepository {
  AuthFalso({List<Usuario> usuarios = const [admin, gestor, executivo], this.sessaoGuardada}) : lista = List.of(usuarios);
  final List<Usuario> lista;
  Usuario? sessaoGuardada;
  int logins = 0;

  @override
  Future<Sessao> login(String email, String senha) async {
    logins++;
    final u = lista.where((u) => u.email == email.trim() && u.ativo).toList();
    if (u.isEmpty || senha != 'senha123') throw ErroApi('E-mail ou senha incorretos');
    return Sessao(token: 'token-${u.first.id}', usuario: u.first);
  }

  @override
  Future<Usuario> quemSou() async {
    final u = sessaoGuardada;
    if (u == null) throw ErroApi('Sessão inválida ou expirada, faça login de novo');
    return u;
  }

  @override
  Future<List<Usuario>> usuarios() async => List.of(lista);

  @override
  Future<Usuario> criarUsuario({required String nome, required String email, required String senha, required Papel papel}) async {
    if (lista.any((u) => u.email == email)) throw ErroApi('já existe um usuário com este e-mail');
    final novo = Usuario(id: 'u${lista.length + 1}', nome: nome, email: email, papel: papel);
    lista.add(novo);
    return novo;
  }

  @override
  Future<Usuario> editarUsuario(String id, {String? nome, Papel? papel, bool? ativo, String? senha}) async {
    final i = lista.indexWhere((u) => u.id == id);
    final atual = lista[i];
    final novo = Usuario(id: id, nome: nome ?? atual.nome, email: atual.email, papel: papel ?? atual.papel, ativo: ativo ?? atual.ativo);
    lista[i] = novo;
    return novo;
  }
}

const comDados = Indicadores(
  semDados: false,
  serie: [
    PontoIndicador(periodo: '2026-09-15', kmTotal: 1250.0, viagens: 100, viagensProgramadas: 102, fcv: 98.04, pagantes: 1200, naoPagantes: 300, total: 1500, mediaPorViagem: 15, diasComDados: 1, diasComPassageiros: 1),
  ],
  totais: Totais(kmTotal: 1250.0, viagens: 100, viagensProgramadas: 102, fcv: 98.04, pagantes: 1200, naoPagantes: 300, total: 1500, mediaPorViagem: 15, diasComDados: 1, diasComPassageiros: 1),
);

final comAnterior = Indicadores(
  semDados: false,
  serie: comDados.serie,
  totais: comDados.totais,
  anterior: PeriodoAnterior(
    inicio: DateTime(2026, 8, 2),
    fim: DateTime(2026, 8, 31),
    totais: const Totais(kmTotal: 1000.0, viagens: 125, viagensProgramadas: 130, fcv: 96.15, pagantes: 1000, naoPagantes: 250, total: 1250, mediaPorViagem: 10, diasComDados: 1, diasComPassageiros: 1),
  ),
);

const porLinha = Indicadores(
  semDados: false,
  serie: [PontoIndicador(periodo: '2026-09-15', kmTotal: 400.0, viagens: 40, diasComDados: 1)],
  totais: Totais(kmTotal: 400.0, viagens: 40, diasComDados: 1),
);

final filtrosPadrao = FiltrosPainel(inicio: DateTime(2026, 9, 1), fim: DateTime(2026, 9, 30));

const _localizacao = [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate];

/// O painel já logado (por padrão como gestor), sem passar pela tela de login.
Widget app(IndicadoresRepository repo, {FiltrosPainel? filtros, Tela tela = Tela.visaoGeral, Usuario usuario = gestor, AuthRepository? auth, VoidCallback? onSair}) => MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: _localizacao,
      home: PainelShell(
        repository: repo,
        authRepository: auth ?? AuthFalso(),
        usuario: usuario,
        onSair: onSair ?? () {},
        filtrosIniciais: filtros ?? filtrosPadrao,
        telaInicial: tela,
      ),
    );

/// O app inteiro, começando pela decisão login/painel (AppRaiz), como em produção.
Widget appCompleto(IndicadoresRepository repo, AuthFalso auth, {String? tokenGuardado}) => MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: _localizacao,
      home: AppRaiz(key: UniqueKey(), sessao: SessaoAtual(), armazenamento: ArmazenamentoMemoria(tokenGuardado), auth: auth, repository: repo),
    );

/// Define a largura da janela de teste (o layout usa LayoutBuilder, então MediaQuery não basta).
void janela(WidgetTester tester, double largura) {
  tester.view.physicalSize = Size(largura, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

String kpi(WidgetTester tester, String titulo) => tester.widget<Text>(find.byKey(Key('kpi-$titulo'))).data!;
