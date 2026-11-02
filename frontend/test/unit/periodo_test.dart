// RN07 e rótulos de período
import 'package:dashmob/core/periodo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RN07 validarIntervalo', () {
    test('intervalo invertido devolve a mensagem de erro', () {
      expect(validarIntervalo(DateTime(2026, 9, 20), DateTime(2026, 9, 10)), mensagemIntervaloInvalido);
    });
    test('datas iguais são válidas', () {
      expect(validarIntervalo(DateTime(2026, 9, 10), DateTime(2026, 9, 10)), isNull);
    });
    test('ignora a hora do dia', () {
      expect(validarIntervalo(DateTime(2026, 9, 10, 23), DateTime(2026, 9, 10, 1)), isNull);
    });
  });

  group('rotuloPeriodo', () {
    test('dia, semana e mês', () {
      expect(rotuloPeriodo('2026-09-15', Granularidade.dia), '15/09');
      expect(rotuloPeriodo('2026-W38', Granularidade.semana), 'S38');
      expect(rotuloPeriodo('2026-09', Granularidade.mes), '09/2026');
    });
    test('chave de outra granularidade não quebra o rótulo', () {
      expect(rotuloPeriodo('2026-09-15', Granularidade.semana), '15/09');
      expect(rotuloPeriodo('2026-W38', Granularidade.dia), 'S38');
    });
  });
}
