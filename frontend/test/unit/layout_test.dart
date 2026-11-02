// US06: faixas de largura do layout responsivo
import 'package:dashmob/core/layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('US06 faixaDeLargura', () {
    test('até 600 dp é compacto', () {
      expect(faixaDeLargura(320), FaixaLargura.compacto);
      expect(faixaDeLargura(599.9), FaixaLargura.compacto);
    });
    test('de 600 a 1024 dp é médio', () {
      expect(faixaDeLargura(600), FaixaLargura.medio);
      expect(faixaDeLargura(1023.9), FaixaLargura.medio);
    });
    test('acima de 1024 dp é expandido', () {
      expect(faixaDeLargura(1024), FaixaLargura.expandido);
      expect(faixaDeLargura(1920), FaixaLargura.expandido);
    });
    test('colunas de cartões por faixa', () {
      expect(colunasDeCartoes(FaixaLargura.compacto), 1);
      expect(colunasDeCartoes(FaixaLargura.medio), 2);
      expect(colunasDeCartoes(FaixaLargura.expandido), 4);
    });
  });
}
