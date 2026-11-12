import 'package:intl/intl.dart';

final _inteiro = NumberFormat.decimalPattern('pt_BR');
final _decimal = NumberFormat('#,##0.0', 'pt_BR');
final _data = DateFormat('dd/MM/yyyy', 'pt_BR');
final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
final _moedaInteira = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

String fmtInteiro(num v) => _inteiro.format(v);
String fmtDecimal(num v) => _decimal.format(v);
String fmtPercentual(num v) => '${NumberFormat('#,##0.00', 'pt_BR').format(v)}%';
String fmtData(DateTime d) => _data.format(d);

/// "R\$ 1.234,56"; com [semCentavos], "R\$ 1.235" (para valores grandes nos cartões).
String fmtMoeda(num v, {bool semCentavos = false}) => (semCentavos ? _moedaInteira : _moeda).format(v).replaceAll('\u00a0', ' ');
String fmtDataApi(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
