import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/tema.dart';
import 'data/indicadores_repository.dart';
import 'features/painel/painel_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  runApp(const DashMobApp());
}

class DashMobApp extends StatelessWidget {
  const DashMobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DashMOB',
      debugShowCheckedModeBanner: false,
      theme: temaDashMob(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: PainelShell(repository: IndicadoresRepositoryHttp()),
    );
  }
}
