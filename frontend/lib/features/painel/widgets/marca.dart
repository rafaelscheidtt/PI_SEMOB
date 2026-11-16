import 'package:flutter/material.dart';

/// Marca do painel: "DASH" fino, um fio amarelo (o da coroa do brasão) e "MOB" em negrito.
class MarcaDashMob extends StatelessWidget {
  const MarcaDashMob({super.key, this.tamanho = 20, this.cor = Colors.white, this.fio = const Color(0xFFFFEF0A)});

  final double tamanho;
  final Color cor;
  final Color fio;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(color: cor, fontSize: tamanho, height: 1.0);
    return Semantics(
      label: 'DashMOB',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: Text('DASH', style: base.copyWith(fontWeight: FontWeight.w400, letterSpacing: tamanho * 0.045), maxLines: 1, softWrap: false, overflow: TextOverflow.clip)),
        Container(
          width: tamanho < 24 ? 2 : 3,
          height: tamanho * 0.86,
          margin: EdgeInsets.only(left: tamanho * 0.12, right: tamanho * 0.2),
          decoration: BoxDecoration(color: fio, borderRadius: BorderRadius.circular(1)),
        ),
        Flexible(child: Text('MOB', style: base.copyWith(fontWeight: FontWeight.w700, letterSpacing: tamanho * 0.02), maxLines: 1, softWrap: false, overflow: TextOverflow.clip)),
      ]),
    );
  }
}
