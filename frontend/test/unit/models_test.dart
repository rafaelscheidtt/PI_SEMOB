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
}
