import 'package:flutter/material.dart';

import '../../../core/tema.dart';
import '../../../core/tema_controle.dart';
import '../../../data/models.dart';
import '../telas.dart';

/// Largura do menu aberto e recolhido (só ícones).
const larguraMenuAberto = 256.0;
const larguraMenuRecolhido = 72.0;

/// Menu lateral azul-escuro do protótipo: logo, grupos Operação, Gestão e Administração e o usuário.
/// Só aparecem as telas que o papel do usuário pode ver (US11). Em modo [compacto] mostra só os
/// ícones, com o nome da tela na dica ao passar o mouse.
class MenuLateral extends StatelessWidget {
  const MenuLateral({
    super.key,
    required this.selecionada,
    required this.onSelecionar,
    required this.usuario,
    required this.onSair,
    this.largura = larguraMenuAberto,
    this.compacto = false,
    this.tema,
  });

  final Tela selecionada;
  final ValueChanged<Tela> onSelecionar;
  final Usuario usuario;
  final VoidCallback onSair;
  final double largura;
  final bool compacto;

  /// Modo claro/escuro; com ele aparece o botão de alternar no rodapé.
  final ControleTema? tema;

  @override
  Widget build(BuildContext context) {
    final telas = Tela.permitidas(usuario.papel);
    final operacao = telas.where((t) => !t.gestao && !t.administracao);
    final gestao = telas.where((t) => t.gestao);
    final administracao = telas.where((t) => t.administracao);
    Widget item(Tela t) => _ItemMenu(tela: t, ativo: t == selecionada, compacto: compacto, onTap: () => onSelecionar(t));
    Widget grupo(String nome) => compacto ? const _Separador() : _TituloGrupo(nome);
    return Container(
      width: largura,
      color: Cores.navy,
      padding: EdgeInsets.fromLTRB(compacto ? 10 : 16, 20, compacto ? 10 : 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Logo(compacto: compacto),
          const SizedBox(height: 10),
          if (!compacto) const _TituloGrupo('Operação'),
          for (final t in operacao) item(t),
          if (gestao.isNotEmpty) ...[
            const SizedBox(height: 12),
            grupo('Gestão'),
            for (final t in gestao) item(t),
          ],
          if (administracao.isNotEmpty) ...[
            const SizedBox(height: 12),
            grupo('Administração'),
            for (final t in administracao) item(t),
          ],
          const Spacer(),
          _Usuario(usuario: usuario, onSair: onSair, compacto: compacto, tema: tema),
        ],
      ),
    );
  }
}

/// Menu que fica recolhido (só ícones) e abre quando o mouse passa por cima, para não
/// ocupar a tela enquanto não está em uso (US06). Em telas de toque os ícones já navegam.
class MenuRetratil extends StatefulWidget {
  const MenuRetratil({super.key, required this.selecionada, required this.onSelecionar, required this.usuario, required this.onSair, this.tema});

  final Tela selecionada;
  final ValueChanged<Tela> onSelecionar;
  final Usuario usuario;
  final VoidCallback onSair;
  final ControleTema? tema;

  @override
  State<MenuRetratil> createState() => _MenuRetratilState();
}

class _MenuRetratilState extends State<MenuRetratil> {
  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      key: const Key('menu-retratil'),
      onEnter: (_) => setState(() => _aberto = true),
      onExit: (_) => setState(() => _aberto = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: _aberto ? larguraMenuAberto : larguraMenuRecolhido,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: larguraMenuAberto,
            child: MenuLateral(
              selecionada: widget.selecionada,
              onSelecionar: (t) {
                setState(() => _aberto = false);
                widget.onSelecionar(t);
              },
              usuario: widget.usuario,
              onSair: widget.onSair,
              tema: widget.tema,
              largura: _aberto ? larguraMenuAberto : larguraMenuRecolhido,
              compacto: !_aberto,
            ),
          ),
        ),
      ),
    );
  }
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Divider(color: Cores.menuEtiqueta, height: 1),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.compacto = false});

  final bool compacto;

  @override
  Widget build(BuildContext context) {
    // brasão da Prefeitura de São Caetano do Sul
    final brasao = Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Image.asset(
        'assets/brasao_scs.png',
        fit: BoxFit.contain,
        errorBuilder: (context, erro, pilha) => const Icon(Icons.location_city, color: Cores.navy, size: 28),
      ),
    );
    if (compacto) {
      return Padding(padding: const EdgeInsets.only(top: 4, bottom: 16), child: Center(child: brasao));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Row(children: [
        brasao,
        const SizedBox(width: 10),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PREFEITURA DE', style: TextStyle(color: Color(0xFF9EA2C7), fontSize: 9, letterSpacing: 1.4)),
            Text('São Caetano do Sul', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('SEMOB · DashMOB', style: TextStyle(color: Color(0xFF9EA2C7), fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

class _TituloGrupo extends StatelessWidget {
  const _TituloGrupo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Text(texto.toUpperCase(), style: const TextStyle(color: Cores.menuTitulo, fontSize: 10, letterSpacing: 1.4)),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({required this.tela, required this.ativo, required this.onTap, this.compacto = false});

  final Tela tela;
  final bool ativo;
  final VoidCallback onTap;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final cor = !tela.disponivel ? Cores.menuApagado : (ativo ? Colors.white : Cores.menuTexto);
    final conteudo = compacto
        ? Tooltip(
            message: tela.rotulo,
            waitDuration: const Duration(milliseconds: 300),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 11), child: Center(child: Icon(tela.icone, size: 18, color: cor))),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(children: [
              Icon(tela.icone, size: 16, color: cor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tela.rotulo,
                  style: TextStyle(color: cor, fontSize: 13.5, fontWeight: ativo ? FontWeight.w600 : FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!tela.disponivel)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Cores.menuEtiqueta, borderRadius: BorderRadius.circular(999)),
                  child: const Text('Sprint 2', style: TextStyle(color: Color(0xFFA9ACD6), fontSize: 10)),
                ),
            ]),
          );
    return Material(
      color: ativo ? Cores.navyClaro : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        key: Key('menu-${tela.name}'),
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: conteudo,
      ),
    );
  }
}

class _Usuario extends StatelessWidget {
  const _Usuario({required this.usuario, required this.onSair, this.compacto = false, this.tema});

  final Usuario usuario;
  final VoidCallback onSair;
  final bool compacto;
  final ControleTema? tema;

  @override
  Widget build(BuildContext context) {
    final t = tema;
    final botaoTema = t == null
        ? null
        : IconButton(
            key: const Key('menu-tema'),
            tooltip: t.escuro ? 'Modo claro' : 'Modo escuro',
            onPressed: t.alternar,
            icon: Icon(t.escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18, color: Cores.menuTexto),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          );
    final sair = IconButton(
      key: const Key('menu-sair'),
      tooltip: 'Sair',
      onPressed: onSair,
      icon: const Icon(Icons.logout, size: 18, color: Cores.menuTexto),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
    if (compacto) {
      return Container(
        padding: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Cores.menuEtiqueta))),
        child: Column(children: [
          Tooltip(
            message: '${usuario.nome} · ${usuario.papel.rotulo}',
            child: const CircleAvatar(radius: 16, backgroundColor: Cores.menuEtiqueta, child: Icon(Icons.person, size: 18, color: Cores.menuTexto)),
          ),
          const SizedBox(height: 6),
          if (botaoTema != null) botaoTema,
          sair,
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Cores.menuEtiqueta))),
      child: Row(children: [
        const CircleAvatar(radius: 16, backgroundColor: Cores.menuEtiqueta, child: Icon(Icons.person, size: 18, color: Cores.menuTexto)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(usuario.nome, key: const Key('menu-usuario-nome'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${usuario.papel.rotulo} · SEMOB', style: const TextStyle(color: Color(0xFF9EA2C7), fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (botaoTema != null) botaoTema,
        sair,
      ]),
    );
  }
}
