// conversão do JSON da API para os modelos
import 'package:dashmob/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _medidas({bool comPassageiros = true}) => {
      'km_total': 275694.5, 'km_produtiva': 261886.8, 'viagens_programadas': 35050, 'viagens_realizadas': 34994,
      'fcv': 99.84,
      'passageiros_pagantes': comPassageiros ? 288378 : null,
      'passageiros_nao_pagantes': comPassageiros ? 761870 : null,
      'passageiros_total': comPassageiros ? 1050248 : null,
      'media_passageiros_por_viagem': comPassageiros ? 30.01 : null,
      'dias_com_dados': 31,
    };

void main() {
  test('Indicadores.fromJson converte série, totais e período anterior', () {
    final d = Indicadores.fromJson({
      'sem_dados': false,
      'serie': [{'periodo': '2026-08', ..._medidas()}],
      'totais': _medidas(),
      'anterior': {'inicio': '2026-07-01', 'fim': '2026-07-31', 'totais': _medidas(comPassageiros: false)},
    });
    expect(d.semDados, isFalse);
    expect(d.serie.single.periodo, '2026-08');
    expect(d.serie.single.total, 1050248); // RN02
    expect(d.totais!.fcv, 99.84); // RN08
    expect(d.totais!.mediaPorViagem, 30.01); // RN03
    expect(d.anterior!.inicio, DateTime(2026, 7, 1));
    expect(d.anterior!.totais.total, isNull);
  });

  test('consulta por linha vem sem passageiros', () {
    final t = Medidas.fromJson({..._medidas(comPassageiros: false), 'viagens_programadas': null, 'fcv': null});
    expect(t.kmTotal, 275694.5);
    expect(t.pagantes, isNull);
    expect(t.fcv, isNull);
  });

  test('RN06 resposta sem dados tem totais nulos', () {
    final d = Indicadores.fromJson({'sem_dados': true, 'serie': [], 'totais': null, 'anterior': null});
    expect(d.semDados, isTrue);
    expect(d.totais, isNull);
    expect(d.serie, isEmpty);
  });

  test('variação percentual em relação ao período anterior', () {
    expect(variacaoPercentual(275694.5, 262800), closeTo(4.91, 0.01));
    expect(variacaoPercentual(34994, 36340), closeTo(-3.70, 0.01));
    expect(variacaoPercentual(100, null), isNull); // sem período anterior
    expect(variacaoPercentual(100, 0), isNull); // base zero não compara
    expect(variacaoPercentual(null, 100), isNull);
  });

  test('Medidas calcula km improdutiva e viagens não realizadas', () {
    final m = Medidas.fromJson(_medidas());
    expect(m.kmImprodutiva, closeTo(13807.7, 0.01));
    expect(m.viagensNaoRealizadas, 56);
    expect(Medidas.fromJson({..._medidas(), 'km_produtiva': null, 'viagens_programadas': null}).kmImprodutiva, isNull);
  });

  test('ResumoLinha soma as ocorrências e calcula km por viagem', () {
    final l = ResumoLinha.fromJson({
      'codigo': '02', 'nome': 'Circular Gerty', 'km_total': 47042.5, 'viagens_realizadas': 5841, 'dias_com_dados': 31,
      'nao_realizadas': 10, 'nao_iniciadas': 1, 'nao_terminadas': 2,
    });
    expect(l.ocorrencias, 13);
    expect(l.kmPorViagem, closeTo(8.05, 0.01));
    expect(const ResumoLinha(codigo: '09', nome: 'x', kmTotal: 0, viagens: 0, diasComDados: 0).kmPorViagem, isNull);
  });

  test('Ocorrencia converte tipo, data e horários opcionais', () {
    final o = Ocorrencia.fromJson({
      'tipo': 'nao_terminada', 'data': '2026-08-03', 'linha': '02', 'atendimento': 'Circular Gerty Sentido Volta',
      'prefixo': '1203', 'sentido': 'V', 'tabela': '7B', 'inicio_programado': '2026-08-03T22:00:00',
      'inicio_realizado': '2026-08-03T22:01:00', 'fim_programado': '2026-08-03T22:20:00', 'fim_realizado': null,
    });
    expect(o.tipo, TipoOcorrencia.naoTerminada);
    expect(o.tipo.rotulo, 'Não terminada');
    expect(o.data, DateTime(2026, 8, 3));
    expect(o.inicioRealizado, DateTime(2026, 8, 3, 22, 1));
    expect(o.fimRealizado, isNull);
    expect(TipoOcorrencia.daApi('inexistente'), TipoOcorrencia.naoRealizada);
  });

  test('DetalhesOperacao converte turnos e faixas e acha o pico', () {
    final d = DetalhesOperacao.fromJson({
      'linha': null,
      'turnos': [
        {'turno': 'manha', 'programadas': 13604, 'realizadas': 13580, 'fcv': 99.82},
        {'turno': 'tarde', 'programadas': 11933, 'realizadas': 11906, 'fcv': 99.77},
      ],
      'faixas_horarias': [
        {'faixa': 5, 'viagens': 1800, 'veiculos': 40},
        {'faixa': 6, 'viagens': 2251, 'veiculos': 52},
        {'faixa': 7, 'viagens': 2100},
      ],
      'pico': {'faixa': 6, 'viagens': 2251},
    });
    expect(d.turnos.first.rotulo, 'Manhã');
    expect(d.turnos.first.fcv, 99.82);
    expect(d.pico!.faixa, 6);
    expect(d.faixasHorarias.last.veiculos, 0);
    expect(DetalhesOperacao.vazio.pico, isNull);
  });

  test('Importacao e ResultadoImportacao aceitam os dois nomes do arquivo', () {
    final historico = Importacao.fromJson({
      '_id': 'abc', 'arquivo_origem': 'Mensal_202608.html', 'tipo_relatorio': 'resumo_geral', 'titulo': 'Resumo Geral',
      'periodicidade': 'mensal', 'periodo_inicio': '2026-08-01T00:00:00', 'periodo_fim': '2026-08-31T00:00:00',
      'total_registros': 31, 'importados': 31, 'rejeitados': 0, 'status': 'concluida', 'importado_em': '2026-10-04T14:32:00',
    });
    expect(historico.arquivo, 'Mensal_202608.html');
    expect(historico.periodoFim, DateTime(2026, 8, 31));
    final r = ResultadoImportacao.fromJson({
      'status': 'concluida', 'arquivos': 1, 'periodo_inicio': '2026-08-01', 'periodo_fim': '2026-08-31',
      'total_registros': 31, 'importados': 31, 'rejeitados': 0, 'inseridos': 0, 'atualizados': 31,
      'relatorios': [
        {'arquivo': 'Mensal_202608.html', 'tipo_relatorio': 'resumo_geral', 'status': 'concluida', 'total_registros': 31,
         'importados': 31, 'rejeitados': 0, 'inseridos': 0, 'atualizados': 31, 'erros': []},
      ],
    });
    expect(r.relatorios.single.arquivo, 'Mensal_202608.html');
    expect(r.atualizados, 31);
  });
}
