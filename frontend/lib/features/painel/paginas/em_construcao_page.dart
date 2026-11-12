import 'package:flutter/material.dart';

import '../../../core/tema.dart';
import '../telas.dart';
import '../widgets/cartao.dart';

/// Tela ainda não implementada: mostra o nome e em qual sprint ela entra.
class EmConstrucaoPage extends StatelessWidget {
  const EmConstrucaoPage({super.key, required this.tela, this.detalhe});

  final Tela tela;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CabecalhoTela(titulo: tela.rotulo, subtitulo: detalhe),
        const SizedBox(height: 18),
        Cartao(
          child: Row(children: [
            Icon(tela.icone, color: Cores.texto2),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tela.emConstrucao ? 'Esta tela está prevista para a Sprint 2.' : 'Esta tela está em desenvolvimento.',
                key: const Key('aviso-em-construcao'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
