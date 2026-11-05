// filtros compartilhados pelas telas e rótulos de período
import 'package:dashmob/core/filtros.dart';
import 'package:dashmob/core/periodo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  test('padrão são os últimos 30 dias', () {
    final f = FiltrosPainel.padrao(DateTime(2026, 9, 30, 15, 40));
    expect(f.fim, DateTime(2026, 9, 30));
    expect(f.inicio, DateTime(2026, 9, 1));
    expect(f.granularidade, Granularidade.dia);
    expect(f.linha, isNull);
  });

  test('mês inteiro vira "Agosto de 2026"; intervalo livre mostra as datas', () {
    expect(FiltrosPainel(inicio: DateTime(2026, 8, 1), fim: DateTime(2026, 8, 31)).descricaoPeriodo, 'Agosto de 2026');
    expect(FiltrosPainel(inicio: DateTime(2026, 8, 1), fim: DateTime(2026, 8, 31)).mesInteiro, isTrue);
    expect(FiltrosPainel(inicio: DateTime(2026, 8, 1), fim: DateTime(2026, 8, 14)).descricaoPeriodo, '01/08/2026 – 14/08/2026');
    expect(FiltrosPainel(inicio: DateTime(2026, 2, 1), fim: DateTime(2026, 2, 28)).mesInteiro, isTrue);
  });

  test('copyWith troca um campo e limparLinha volta para o sistema inteiro', () {
    final f = FiltrosPainel(inicio: DateTime(2026, 8, 1), fim: DateTime(2026, 8, 31), linha: '02');
    expect(f.copyWith(granularidade: Granularidade.mes).linha, '02');
    expect(f.copyWith(limparLinha: true).linha, isNull);
    expect(f.copyWith(linha: '03'), FiltrosPainel(inicio: DateTime(2026, 8, 1), fim: DateTime(2026, 8, 31), linha: '03'));
    expect(f == f.copyWith(fim: DateTime(2026, 8, 30)), isFalse);
  });

  test('rótulo da comparação usa o mês abreviado quando o anterior é um mês inteiro', () {
    expect(rotuloComparacao(DateTime(2026, 7, 1), DateTime(2026, 7, 31)), 'vs. jul.');
    expect(rotuloComparacao(DateTime(2026, 8, 1), DateTime(2026, 8, 14)), 'vs. anterior');
  });
}
