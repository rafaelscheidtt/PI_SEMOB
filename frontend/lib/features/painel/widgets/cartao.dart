import 'package:flutter/material.dart';

import '../../../core/tema.dart';

/// Cartão branco com borda fina, a base de todos os blocos do painel.
class Cartao extends StatelessWidget {
  const Cartao({
    super.key,
    required this.child,
    this.titulo,
    this.subtitulo,
    this.acao,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
  });

  final Widget child;
  final String? titulo;
  final String? subtitulo;

  /// Widget alinhado à direita do título (etiqueta, legenda, botão).
  final Widget? acao;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Cores.linha),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titulo != null) ...[
            _cabecalho(context),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }

  /// Título à esquerda e a ação à direita; em cartões estreitos a ação desce para baixo do título.
  Widget _cabecalho(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final titulos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo!, style: tema.titleMedium),
        if (subtitulo != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitulo!, style: tema.bodySmall)),
      ],
    );
    if (acao == null) return titulos;
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 480) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titulos, const SizedBox(height: 10), acao!]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titulos),
          const SizedBox(width: 12),
          Flexible(child: acao!),
        ],
      );
    });
  }
}

enum TomEtiqueta { ok, negativo, aviso, info, neutro }

/// Etiqueta arredondada ("pill"): +4,9% vs. jul., Concluída, Sprint 2...
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, this.tom = TomEtiqueta.neutro});

  final String texto;
  final TomEtiqueta tom;

  @override
  Widget build(BuildContext context) {
    final (fundo, cor) = switch (tom) {
      TomEtiqueta.ok => (Cores.verdeSuave, Cores.verde),
      TomEtiqueta.negativo => (Cores.vermelhoSuave, Cores.vermelho),
      TomEtiqueta.aviso => (Cores.ambarSuave, Cores.ambar),
      TomEtiqueta.info => (Cores.azulSuave, Cores.azul),
      TomEtiqueta.neutro => (Cores.fundo, Cores.texto2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
        border: tom == TomEtiqueta.neutro ? Border.all(color: Cores.linha) : null,
      ),
      child: Text(texto, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cor), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// Rótulo pequeno em caixa alta, usado nos cartões de indicador e nos cabeçalhos de tabela.
class Rotulo extends StatelessWidget {
  const Rotulo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: Cores.texto2),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Código da linha em um quadrado azul-escuro, como no protótipo.
class CodigoLinha extends StatelessWidget {
  const CodigoLinha(this.codigo, {super.key});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Cores.navy, borderRadius: BorderRadius.circular(5)),
      child: Text(codigo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5)),
    );
  }
}

/// Título e subtítulo de uma tela, com espaço para etiquetas à direita.
class CabecalhoTela extends StatelessWidget {
  const CabecalhoTela({super.key, required this.titulo, this.subtitulo, this.acoes = const []});

  final String titulo;
  final String? subtitulo;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final titulos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: tema.titleLarge),
        if (subtitulo != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitulo!, style: tema.bodySmall)),
      ],
    );
    if (acoes.isEmpty) return titulos;
    return LayoutBuilder(builder: (context, c) {
      final etiquetas = Wrap(spacing: 8, runSpacing: 8, children: acoes);
      if (c.maxWidth < 640) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titulos, const SizedBox(height: 10), etiquetas]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [Expanded(child: titulos), const SizedBox(width: 16), etiquetas],
      );
    });
  }
}
