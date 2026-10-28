// cartão de indicador: valor, variação e "Sem dados" (RN06)
import 'package:dashmob/features/painel/widgets/cartao.dart';
import 'package:dashmob/features/painel/widgets/kpi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Widget _app(Widget filho) => MaterialApp(home: Scaffold(body: Center(child: SizedBox(width: 320, height: 170, child: filho))));

void main() {
  setUpAll(() async => initializeDateFormatting('pt_BR'));

  testWidgets('mostra valor, unidade, detalhe e a alta em verde', (tester) async {
    await tester.pumpWidget(_app(const KpiCard(
      titulo: 'Quilometragem',
      valor: '275.694',
      unidade: 'km',
      detalhe: '261.887 km produtiva',
      variacao: 4.9,
      rotuloVariacao: 'vs. jul.',
      serie: [1, 2, 3],
    )));
    expect(tester.widget<Text>(find.byKey(const Key('kpi-Quilometragem'))).data, '275.694');
    expect(find.text('km'), findsOneWidget);
    expect(find.text('261.887 km produtiva'), findsOneWidget);
    expect(find.text('+4,9% vs. jul.'), findsOneWidget);
    expect(tester.widget<Etiqueta>(find.byType(Etiqueta)).tom, TomEtiqueta.ok);
  });

  testWidgets('queda fica em vermelho, salvo quando cair é bom', (tester) async {
    await tester.pumpWidget(_app(const KpiCard(titulo: 'Viagens realizadas', valor: '34.994', variacao: -3.7)));
    expect(find.text('−3,7% vs. anterior'), findsOneWidget);
    expect(tester.widget<Etiqueta>(find.byType(Etiqueta)).tom, TomEtiqueta.negativo);

    await tester.pumpWidget(_app(const KpiCard(titulo: 'Ocorrências', valor: '13', etiqueta: EtiquetaVariacao(-20, quedaEBoa: true))));
    expect(tester.widget<Etiqueta>(find.byType(Etiqueta)).tom, TomEtiqueta.ok);
  });

  testWidgets('RN06 valor nulo vira "Sem dados", sem variação e sem zero', (tester) async {
    await tester.pumpWidget(_app(const KpiCard(titulo: 'Passageiros', valor: null, variacao: 10)));
    expect(tester.widget<Text>(find.byKey(const Key('kpi-Passageiros'))).data, 'Sem dados');
    expect(find.byType(Etiqueta), findsNothing);
    expect(find.text('0'), findsNothing);
  });
}
