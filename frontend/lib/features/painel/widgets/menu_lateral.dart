import 'package:flutter/material.dart';

import '../../../core/tema.dart';
import '../../../core/tema_controle.dart';
import '../../../data/models.dart';
import '../telas.dart';
import 'avatar_usuario.dart';
import 'marca.dart';

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
    this.onPerfil,
  });

  final Tela selecionada;
  final ValueChanged<Tela> onSelecionar;
  final Usuario usuario;
  final VoidCallback onSair;
  final double largura;
  final bool compacto;

  /// Modo claro/escuro; com ele aparece o botão de alternar no rodapé.
  final ControleTema? tema;

  /// Abre "Meu perfil" ao tocar no nome ou na foto do rodapé; sem ele o rodapé não é clicável.
  final VoidCallback? onPerfil;

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
          _Usuario(usuario: usuario, onSair: onSair, compacto: compacto, tema: tema, onPerfil: onPerfil),
        ],
      ),
    );
  }
}

/// Menu que fica recolhido (só ícones) e abre quando o mouse passa por cima, para não
/// ocupar a tela enquanto não está em uso (US06). Em telas de toque os ícones já navegam.
class MenuRetratil extends StatefulWidget {
  const MenuRetratil({super.key, required this.selecionada, required this.onSelecionar, required this.usuario, required this.onSair, this.tema, this.onPerfil});

  final Tela selecionada;
  final ValueChanged<Tela> onSelecionar;
  final Usuario usuario;
  final VoidCallback onSair;
  final ControleTema? tema;
  final VoidCallback? onPerfil;

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
              onPerfil: widget.onPerfil,
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
    // brasão da Prefeitura de São Caetano do Sul, direto sobre o azul do menu (o arquivo tem fundo transparente)
    Widget brasao(double altura) => Image.asset(
          'assets/brasao.png',
          height: altura,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, erro, pilha) => Icon(Icons.location_city, color: Colors.white, size: altura * 0.7),
        );
    const divisa = BoxDecoration(border: Border(bottom: BorderSide(color: Cores.menuEtiqueta)));
    if (compacto) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(bottom: 14),
        decoration: divisa,
        child: Center(child: brasao(42)),
      );
    }
    // assinatura: brasão, um fio vertical e o nome do painel com a secretaria embaixo
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 14),
      decoration: divisa,
      child: Row(children: [
        brasao(46),
        Container(width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 12), color: Colors.white.withValues(alpha: 0.18)),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MarcaDashMob(tamanho: 19),
            SizedBox(height: 6),
            Text('SEMOB · São Caetano do Sul', style: TextStyle(color: Color(0xFF9EA2C7), fontSize: 10.5), maxLines: 1, overflow: TextOverflow.ellipsis),
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
    final cor = ativo ? Colors.white : Cores.menuTexto;
    // marca fina na cor da tela, só no item aberto
    final marca = AnimatedContainer(
      duration: _duracao,
      width: 3,
      height: 18,
      decoration: BoxDecoration(color: ativo ? tela.cor : tela.cor.withValues(alpha: 0), borderRadius: BorderRadius.circular(2)),
    );
    final conteudo = compacto
        ? Tooltip(
            message: tela.rotulo,
            waitDuration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(children: [marca, Expanded(child: Center(child: Icon(tela.icone, size: 18, color: cor))), const SizedBox(width: 3)]),
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(right: 10, top: 9, bottom: 9),
            child: Row(children: [
              marca,
              const SizedBox(width: 9),
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
            ]),
          );
    return AnimatedContainer(
      duration: _duracao,
      decoration: BoxDecoration(color: ativo ? Cores.navyClaro : Cores.navyClaro.withValues(alpha: 0), borderRadius: BorderRadius.circular(7)),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('menu-${tela.name}'),
          borderRadius: BorderRadius.circular(7),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          onTap: onTap,
          child: conteudo,
        ),
      ),
    );
  }
}

const _duracao = Duration(milliseconds: 180);

class _Usuario extends StatelessWidget {
  const _Usuario({required this.usuario, required this.onSair, this.compacto = false, this.tema, this.onPerfil});

  final Usuario usuario;
  final VoidCallback onSair;
  final bool compacto;
  final ControleTema? tema;
  final VoidCallback? onPerfil;

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
    final avatar = AvatarUsuario.de(usuario, raio: 16, fundo: Cores.menuEtiqueta, corTexto: Colors.white);
    // a foto e o nome abrem "Meu perfil"
    Widget clicavel(Widget filho, {BorderRadius? raio}) => onPerfil == null
        ? filho
        : Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const Key('menu-perfil'),
              onTap: onPerfil,
              borderRadius: raio ?? BorderRadius.circular(7),
              hoverColor: Colors.white.withValues(alpha: 0.06),
              child: filho,
            ),
          );
    if (compacto) {
      return Container(
        padding: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Cores.menuEtiqueta))),
        child: Column(children: [
          Tooltip(
            message: '${usuario.nome} · ${usuario.papel.rotulo}',
            child: clicavel(Padding(padding: const EdgeInsets.all(2), child: avatar), raio: BorderRadius.circular(20)),
          ),
          const SizedBox(height: 4),
          if (botaoTema != null) botaoTema,
          sair,
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Cores.menuEtiqueta))),
      child: Row(children: [
        Expanded(
          child: Tooltip(
            message: onPerfil == null ? '' : 'Meu perfil',
            waitDuration: const Duration(milliseconds: 500),
            child: clicavel(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Row(children: [
                  avatar,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(usuario.nome, key: const Key('menu-usuario-nome'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${usuario.papel.rotulo} · SEMOB', style: const TextStyle(color: Color(0xFF9EA2C7), fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
        if (botaoTema != null) botaoTema,
        sair,
      ]),
    );
  }
}
