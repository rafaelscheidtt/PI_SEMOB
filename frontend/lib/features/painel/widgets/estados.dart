import 'package:flutter/material.dart';

import '../../../core/tema.dart';

/// Indicador de carregamento usado por todas as telas.
class Carregando extends StatelessWidget {
  const Carregando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
  }
}

/// Faixa de erro (intervalo inválido, API fora do ar...).
class MensagemErro extends StatelessWidget {
  const MensagemErro(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.vermelhoSuave,
        border: Border.all(color: const Color(0xFFF2C4BE)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Cores.vermelho, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, key: const Key('mensagem-erro'), style: const TextStyle(color: Cores.vermelho))),
      ]),
    );
  }
}

/// Aviso de período sem dados (RN06): nunca mostramos zero no lugar.
class AvisoSemDados extends StatelessWidget {
  const AvisoSemDados({super.key, this.texto = 'Sem dados para o período selecionado'});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inbox_outlined, size: 36, color: Cores.texto2),
          const SizedBox(height: 10),
          Text(texto, key: const Key('aviso-sem-dados'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Importe os relatórios do período ou escolha outro intervalo.', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}

/// Faixa azul de informação.
class Aviso extends StatelessWidget {
  const Aviso(this.texto, {super.key, this.chave});

  final String texto;
  final Key? chave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Cores.azulSuave,
        border: Border.all(color: const Color(0xFFC9D4F5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: Cores.azul, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, key: chave, style: const TextStyle(color: Cores.azul, fontSize: 13))),
      ]),
    );
  }
}
