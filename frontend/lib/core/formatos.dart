import 'package:intl/intl.dart';

final _inteiro = NumberFormat.decimalPattern('pt_BR');
final _decimal = NumberFormat('#,##0.0', 'pt_BR');
final _data = DateFormat('dd/MM/yyyy', 'pt_BR');

String fmtInteiro(num v) => _inteiro.format(v);
String fmtDecimal(num v) => _decimal.format(v);
String fmtPercentual(num v) => '${NumberFormat('#,##0.00', 'pt_BR').format(v)}%';
String fmtData(DateTime d) => _data.format(d);
String fmtDataApi(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
