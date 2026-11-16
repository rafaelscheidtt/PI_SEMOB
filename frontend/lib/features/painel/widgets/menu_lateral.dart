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
///
/// Os ícones, o brasão e a foto ficam exatamente no mesmo lugar nos dois modos: o que muda é só
/// se o texto ao lado existe. Assim nada pula quando o menu abre ou recolhe.
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
    this.fixo = false,
    this.onFixar,
    this.abertura = 1,
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

  /// Menu travado aberto (só faz sentido no menu que recolhe).
  final bool fixo;

  /// Trava ou solta o menu aberto; com ele aparece o alfinete ao lado de "Operação".
  final VoidCallback? onFixar;

  /// Quanto o menu já abriu, de 0 a 1: os textos vão aparecendo junto com a largura.
  final double abertura;

  @override
  Widget build(BuildContext context) {
    final telas = Tela.permitidas(usuario.papel);
    final operacao = telas.where((t) => !t.gestao && !t.administracao);
    final gestao = telas.where((t) => t.gestao);
    final administracao = telas.where((t) => t.administracao);
    // os textos só começam a aparecer quando já há espaço para eles
    final opacidade = compacto ? 0.0 : ((abertura - 0.35) / 0.65).clamp(0.0, 1.0);
    Widget item(Tela t) => _ItemMenu(tela: t, ativo: t == selecionada, compacto: compacto, opacidade: opacidade, onTap: () => onSelecionar(t));
    Widget grupo(String nome, {bool primeiro = false}) => _TituloGrupo(
          nome,
          compacto: compacto,
          opacidade: opacidade,
          comFio: !primeiro,
          acao: primeiro && onFixar != null ? _BotaoFixar(fixo: fixo, onTap: onFixar!) : null,
        );
    return Container(
      width: largura,
      color: Cores.navy,
      padding: const EdgeInsets.fromLTRB(_margem, 20, _margem, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Logo(compacto: compacto, opacidade: opacidade, onFixar: compacto ? onFixar : null),
          // a lista rola se a janela for baixa demais para caber tudo; sem a barra de rolagem,
          // que piscava no canto enquanto o menu abria e fechava
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  grupo('Operação', primeiro: true),
                  for (final t in operacao) item(t),
                  if (gestao.isNotEmpty) ...[
                    grupo('Gestão'),
                    for (final t in gestao) item(t),
                  ],
                  if (administracao.isNotEmpty) ...[
                    grupo('Administração'),
                    for (final t in administracao) item(t),
                  ],
                ]),
              ),
            ),
          ),
          const SizedBox(height: 6),
          item(Tela.sobre),
          const SizedBox(height: 8),
          _Usuario(usuario: usuario, onSair: onSair, compacto: compacto, opacidade: opacidade, tema: tema, onPerfil: onPerfil),
        ],
      ),
    );
  }
}

/// Margem lateral do menu e medidas das linhas, iguais com ele aberto ou recolhido.
/// Com 14 de margem, a coluna dos ícones fica centrada nos 72 px do menu recolhido.
const _margem = 14.0;
const _alturaItem = 38.0;
const _alturaTitulo = 30.0;
const _duracao = Duration(milliseconds: 180);

/// Menu que fica recolhido (só ícones) e abre quando o mouse passa por cima, para não
/// ocupar a tela enquanto não está em uso (US06). Em telas de toque os ícones já navegam.
/// Aberto pelo mouse ele passa por cima do conteúdo, sem empurrar nada; com [fixo] fica
/// aberto de vez (aí quem o usa reserva o espaço, veja o PainelShell).
class MenuRetratil extends StatefulWidget {
  const MenuRetratil({
    super.key,
    required this.selecionada,
    required this.onSelecionar,
    required this.usuario,
    required this.onSair,
    this.tema,
    this.onPerfil,
    this.fixo = false,
    this.onFixar,
  });

  final Tela selecionada;
  final ValueChanged<Tela> onSelecionar;
  final Usuario usuario;
  final VoidCallback onSair;
  final ControleTema? tema;
  final VoidCallback? onPerfil;
  final bool fixo;
  final VoidCallback? onFixar;

  @override
  State<MenuRetratil> createState() => _MenuRetratilState();
}

class _MenuRetratilState extends State<MenuRetratil> with SingleTickerProviderStateMixin {
  late final AnimationController _abertura = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 200),
    value: widget.fixo ? 1 : 0,
  );
  late final Animation<double> _curva = CurvedAnimation(parent: _abertura, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
  bool _mouseEmCima = false;

  void _ajustar() {
    if (widget.fixo || _mouseEmCima) {
      _abertura.forward();
    } else {
      _abertura.reverse();
    }
  }

  @override
  void didUpdateWidget(MenuRetratil antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.fixo != widget.fixo) _ajustar();
  }

  @override
  void dispose() {
    _abertura.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      key: const Key('menu-retratil'),
      onEnter: (_) {
        _mouseEmCima = true;
        _ajustar();
      },
      onExit: (_) {
        _mouseEmCima = false;
        _ajustar();
      },
      child: AnimatedBuilder(
        animation: _abertura,
        builder: (context, _) {
          // só vira "só ícones" quando termina de fechar; enquanto anda, é o menu inteiro
          // sendo descoberto, e por isso os nomes não pulam nem quebram no meio do caminho
          final fechado = _abertura.isDismissed;
          final largura = larguraMenuRecolhido + (larguraMenuAberto - larguraMenuRecolhido) * _curva.value;
          final larguraDoMenu = fechado ? larguraMenuRecolhido : larguraMenuAberto;
          return Container(
            width: largura,
            // sombra na borda enquanto ele está por cima do conteúdo
            decoration: BoxDecoration(
              boxShadow: fechado || widget.fixo ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.28 * _curva.value), blurRadius: 18, offset: const Offset(4, 0))],
            ),
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: larguraDoMenu,
                maxWidth: larguraDoMenu,
                child: MenuLateral(
                  selecionada: widget.selecionada,
                  onSelecionar: (t) {
                    // em tela de toque não existe "tirar o mouse": escolher a tela já recolhe
                    _mouseEmCima = false;
                    _ajustar();
                    widget.onSelecionar(t);
                  },
                  usuario: widget.usuario,
                  onSair: widget.onSair,
                  tema: widget.tema,
                  onPerfil: widget.onPerfil,
                  fixo: widget.fixo,
                  onFixar: widget.onFixar,
                  largura: larguraDoMenu,
                  compacto: fechado,
                  abertura: _curva.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.compacto, required this.opacidade, this.onFixar});

  final bool compacto;
  final double opacidade;

  /// No menu recolhido, tocar no brasão trava o menu aberto (é o caminho em telas de toque, sem mouse).
  final VoidCallback? onFixar;

  @override
  Widget build(BuildContext context) {
    // brasão da Prefeitura de São Caetano do Sul, direto sobre o azul do menu (o arquivo tem fundo transparente)
    Widget brasao = Image.asset(
      'assets/brasao.png',
      width: 44,
      height: 44,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, erro, pilha) => const SizedBox(width: 44, height: 44, child: Icon(Icons.location_city, color: Colors.white, size: 30)),
    );
    if (onFixar != null) {
      brasao = Tooltip(
        message: 'Manter o menu aberto',
        child: GestureDetector(key: const Key('menu-abrir'), behavior: HitTestBehavior.opaque, onTap: onFixar, child: brasao),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Cores.menuEtiqueta))),
      child: Row(children: [
        brasao,
        if (!compacto)
          Expanded(
            child: Opacity(
              opacity: opacidade,
              child: Row(children: [
                Container(width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 12), color: Colors.white.withValues(alpha: 0.18)),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    MarcaDashMob(tamanho: 19),
                    SizedBox(height: 6),
                    Text('SEMOB · São Caetano do Sul', style: TextStyle(color: Color(0xFF9EA2C7), fontSize: 10.5), maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Título de um grupo do menu. Ocupa sempre a mesma altura: aberto mostra o nome,
/// recolhido mostra um fio no lugar (menos no primeiro grupo, que já vem depois do fio do logo).
class _TituloGrupo extends StatelessWidget {
  const _TituloGrupo(this.texto, {required this.compacto, required this.opacidade, this.comFio = true, this.acao});

  final String texto;
  final bool compacto;
  final double opacidade;
  final bool comFio;

  /// Botão pequeno no fim da linha (o alfinete de travar o menu).
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    if (compacto) {
      return SizedBox(
        height: _alturaTitulo,
        child: comFio ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Divider(color: Cores.menuEtiqueta, height: 1))) : null,
      );
    }
    return SizedBox(
      height: _alturaTitulo,
      child: Opacity(
        opacity: opacidade,
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 6),
          child: Row(children: [
            Expanded(
              child: Text(texto.toUpperCase(), style: const TextStyle(color: Cores.menuTitulo, fontSize: 10, letterSpacing: 1.4), maxLines: 1, softWrap: false, overflow: TextOverflow.clip),
            ),
            if (acao != null) acao!,
          ]),
        ),
      ),
    );
  }
}

/// Alfinete que trava o menu aberto (ou solta, para ele voltar a recolher sozinho).
class _BotaoFixar extends StatelessWidget {
  const _BotaoFixar({required this.fixo, required this.onTap});

  final bool fixo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: fixo ? 'Soltar o menu' : 'Manter o menu aberto',
      child: InkResponse(
        key: const Key('menu-fixar'),
        onTap: onTap,
        radius: 14,
        child: SizedBox(width: 24, height: 24, child: Icon(fixo ? Icons.push_pin : Icons.push_pin_outlined, size: 15, color: fixo ? Colors.white : Cores.menuTexto)),
      ),
    );
  }
}

class _ItemMenu extends StatelessWidget {
  const _ItemMenu({required this.tela, required this.ativo, required this.onTap, required this.compacto, required this.opacidade});

  final Tela tela;
  final bool ativo;
  final VoidCallback onTap;
  final bool compacto;
  final double opacidade;

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
    // marca (3) + espaço (9) + ícone (20): o centro do ícone cai no meio do menu recolhido
    final linha = SizedBox(
      height: _alturaItem,
      child: Row(children: [
        marca,
        const SizedBox(width: 9),
        SizedBox(width: 20, child: Icon(tela.icone, size: 17, color: cor)),
        if (!compacto) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Opacity(
              opacity: opacidade,
              child: Text(
                tela.rotulo,
                style: TextStyle(color: cor, fontSize: 13.5, fontWeight: ativo ? FontWeight.w600 : FontWeight.w400),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
          child: compacto ? Tooltip(message: tela.rotulo, waitDuration: const Duration(milliseconds: 300), child: linha) : linha,
        ),
      ),
    );
  }
}

class _Usuario extends StatelessWidget {
  const _Usuario({required this.usuario, required this.onSair, required this.compacto, required this.opacidade, this.tema, this.onPerfil});

  final Usuario usuario;
  final VoidCallback onSair;
  final bool compacto;
  final double opacidade;
  final ControleTema? tema;
  final VoidCallback? onPerfil;

  @override
  Widget build(BuildContext context) {
    final t = tema;
    // a foto fica na mesma coluna dos ícones (centro em 36 px), aberto ou recolhido
    final avatar = Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      child: AvatarUsuario.de(usuario, raio: 16, fundo: Cores.menuEtiqueta, corTexto: Colors.white),
    );
    // a foto e o nome abrem "Meu perfil"
    Widget clicavel(Widget filho) => onPerfil == null
        ? filho
        : Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const Key('menu-perfil'),
              onTap: onPerfil,
              borderRadius: BorderRadius.circular(7),
              hoverColor: Colors.white.withValues(alpha: 0.06),
              child: filho,
            ),
          );
    const borda = BoxDecoration(border: Border(top: BorderSide(color: Cores.menuEtiqueta)));
    if (compacto) {
      // recolhido fica só a foto; modo escuro e sair aparecem quando o menu abre
      return Container(
        padding: const EdgeInsets.only(top: 10),
        decoration: borda,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(message: '${usuario.nome} · ${usuario.papel.rotulo}', child: clicavel(avatar)),
        ),
      );
    }
    Widget botao({required Key chave, required String dica, required IconData icone, required VoidCallback aoTocar}) => IconButton(
          key: chave,
          tooltip: dica,
          onPressed: aoTocar,
          icon: Icon(icone, size: 18, color: Cores.menuTexto),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        );
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: borda,
      child: Row(children: [
        Expanded(
          child: Tooltip(
            message: onPerfil == null ? '' : 'Meu perfil',
            waitDuration: const Duration(milliseconds: 500),
            child: clicavel(
              Row(children: [
                avatar,
                const SizedBox(width: 4),
                Expanded(
                  child: Opacity(
                    opacity: opacidade,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(usuario.nome, key: const Key('menu-usuario-nome'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                      Text('${usuario.papel.rotulo} · SEMOB', style: const TextStyle(color: Color(0xFF9EA2C7), fontSize: 11.5), maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Opacity(
          opacity: opacidade,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (t != null) botao(chave: const Key('menu-tema'), dica: t.escuro ? 'Modo claro' : 'Modo escuro', icone: t.escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined, aoTocar: t.alternar),
            botao(chave: const Key('menu-sair'), dica: 'Sair', icone: Icons.logout, aoTocar: onSair),
          ]),
        ),
      ]),
    );
  }
}
