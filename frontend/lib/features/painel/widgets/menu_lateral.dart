import 'package:flutter/material.dart';

import '../../../core/tema.dart';
import '../../../data/models.dart';
import '../telas.dart';

/// Menu lateral azul-escuro do protótipo: logo, grupos Operação, Gestão e Administração e o usuário.
/// Só aparecem as telas que o papel do usuário pode ver (US11).
class MenuLateral extends StatelessWidget {
  const MenuLateral({
    super.key,
    required this.selecionada,
    required this.onSelecionar,
    required this.usuario,
    required this.onSair,
    this.largura = 256,
  });

  final Tela selecionada;
  final ValueChanged<Tela> onSelecionar;
  final Usuario usuario;
  final VoidCallback onSair;
  final double largura;

  @override
  Widget build(BuildContext context) {
    final telas = Tela.permitidas(usuario.papel);
    final operacao = telas.where((t) => !t.gestao && !t.administracao);
    final gestao = telas.where((t) => t.gestao);
    final administracao = telas.where((t) => t.administracao);
    return Container(
      width: largura,
      color: Cores.navy,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Logo(),
          const SizedBox(height: 10),
          const _TituloGrupo('Operação'),
          for (final t in operacao) _ItemMenu(tela: t, ativo: t == selecionada, onTap: () => onSelecionar(t)),
          if (gestao.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _TituloGrupo('Gestão'),
            for (final t in gestao) _ItemMenu(tela: t, ativo: false, onTap: null),
          ],
          if (administracao.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _TituloGrupo('Administração'),
            for (final t in administracao) _ItemMenu(tela: t, ativo: t == selecionada, onTap: () => onSelecionar(t)),
          ],
          const Spacer(),
          _Usuario(usuario: usuario, onSair: onSair),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
      child: Row(children: [
        // brasão da Prefeitura de São Caetano do Sul
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Image.asset(
            'assets/brasao_scs.png',
            fit: BoxFit.contain,
            errorBuilder: (context, erro, pilha) => const Icon(Icons.location_city, color: Cores.navy, size: 28),
          ),
        ),
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
  const _ItemMenu({required this.tela, required this.ativo, required this.onTap});

  final Tela tela;
  final bool ativo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cor = onTap == null ? Cores.menuApagado : (ativo ? Colors.white : Cores.menuTexto);
    return Material(
      color: ativo ? Cores.navyClaro : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        key: Key('menu-${tela.name}'),
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(
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
            if (tela.gestao)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: Cores.menuEtiqueta, borderRadius: BorderRadius.circular(999)),
                child: const Text('Sprint 2', style: TextStyle(color: Color(0xFFA9ACD6), fontSize: 10)),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Usuario extends StatelessWidget {
  const _Usuario({required this.usuario, required this.onSair});

  final Usuario usuario;
  final VoidCallback onSair;

  @override
  Widget build(BuildContext context) {
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
        IconButton(
          key: const Key('menu-sair'),
          tooltip: 'Sair',
          onPressed: onSair,
          icon: const Icon(Icons.logout, size: 18, color: Cores.menuTexto),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ]),
    );
  }
}
