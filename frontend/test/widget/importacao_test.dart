// tela de importação: envio do pacote e histórico (US01)
import 'package:dashmob/data/indicadores_repository.dart';
import 'package:dashmob/data/models.dart';
import 'package:dashmob/features/painel/paginas/importacao_page.dart';
import 'package:dashmob/features/painel/widgets/cartao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'apoio.dart';

final _historico = [
  Importacao(arquivo: 'Mensal_202608.html', titulo: 'Resumo Geral', status: 'concluida', totalRegistros: 31, importados: 31, rejeitados: 0,
      periodoInicio: DateTime(2026, 8, 1), periodoFim: DateTime(2026, 8, 31), importadoEm: DateTime(2026, 10, 4, 14, 32)),
  const Importacao(arquivo: 'relatorio_frota.xlsx', status: 'falha', totalRegistros: 0, importados: 0, rejeitados: 0),
];

const _resultado = ResultadoImportacao(
  status: 'concluida',
  arquivos: 11,
  totalRegistros: 43460,
  importados: 43460,
  rejeitados: 0,
  inseridos: 0,
  atualizados: 43460,
  relatorios: [
    Importacao(arquivo: 'Mensal_202608.html', titulo: 'Resumo Geral', status: 'concluida', totalRegistros: 31, importados: 31, rejeitados: 0),
  ],
);

Widget _tela(IndicadoresRepository repo, {EscolherArquivos? escolher}) => MaterialApp(
      home: Scaffold(body: ImportacaoPage(repository: repo, escolherArquivos: escolher ?? () async => const [])),
    );

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  testWidgets('mostra o histórico com o status de cada relatório', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(_tela(RepositorioFalso(comDados, historico: _historico)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tabela-historico')), findsOneWidget);
    expect(find.text('Mensal_202608.html'), findsOneWidget);
    expect(find.text('04/10/2026 14:32'), findsOneWidget);
    expect(find.text('01/08/2026 – 31/08/2026'), findsOneWidget);
    expect(find.text('Concluída'), findsOneWidget);
    expect(find.text('Falha'), findsOneWidget);
    expect(find.text('não reconhecido'), findsOneWidget);
  });

  testWidgets('US01 importa os arquivos escolhidos e informa "11 arquivos importados"', (tester) async {
    janela(tester, 1400);
    final repo = RepositorioFalso(comDados, resultadoImportacao: _resultado);
    await tester.pumpWidget(_tela(repo, escolher: () async => const [ArquivoEnvio(nome: 'Mensal_202608.html', bytes: [60, 104, 116, 109, 108, 62])]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-escolher-arquivos')));
    await tester.pumpAndSettle();
    expect(repo.arquivosEnviados!.single.nome, 'Mensal_202608.html');
    expect(find.text('11 arquivos importados'), findsOneWidget);
    expect(find.text('43.460 importados, 0 rejeitados'), findsOneWidget);
    expect(tester.widget<Etiqueta>(find.byType(Etiqueta).first).texto, 'Concluída');
  });

  testWidgets('falha na API aparece como mensagem de erro', (tester) async {
    janela(tester, 1400);
    await tester.pumpWidget(_tela(RepositorioFalso(comDados), escolher: () async => const [ArquivoEnvio(nome: 'x.html', bytes: [1])]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-escolher-arquivos')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mensagem-erro')), findsOneWidget);
    expect(find.text('Não foi possível importar os arquivos'), findsOneWidget);
  });

  testWidgets('cancelar a escolha de arquivos não chama a API', (tester) async {
    janela(tester, 1400);
    final repo = RepositorioFalso(comDados, resultadoImportacao: _resultado);
    await tester.pumpWidget(_tela(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-escolher-arquivos')));
    await tester.pumpAndSettle();
    expect(repo.arquivosEnviados, isNull);
    expect(find.text('11 arquivos importados'), findsNothing);
  });
}
