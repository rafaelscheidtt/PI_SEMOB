import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/models.dart';

/// Bytes da imagem de um data URL ("data:image/png;base64,..."), ou `null` se não der para ler.
Uint8List? bytesDaFoto(String? foto) {
  if (foto == null) return null;
  final virgula = foto.indexOf(',');
  if (virgula < 0) return null;
  try {
    return base64Decode(foto.substring(virgula + 1));
  } on FormatException {
    return null;
  }
}

/// Círculo com a foto do usuário; sem foto, as iniciais do nome.
class AvatarUsuario extends StatefulWidget {
  const AvatarUsuario({super.key, required this.iniciais, this.foto, this.raio = 16, required this.fundo, required this.corTexto});

  /// Atalho para quando já se tem o [Usuario] em mãos.
  AvatarUsuario.de(Usuario usuario, {super.key, this.raio = 16, required this.fundo, required this.corTexto})
      : iniciais = usuario.iniciais,
        foto = usuario.foto;

  /// Mostradas quando não há foto.
  final String iniciais;
  final String? foto;
  final double raio;
  final Color fundo;
  final Color corTexto;

  @override
  State<AvatarUsuario> createState() => _AvatarUsuarioState();
}

class _AvatarUsuarioState extends State<AvatarUsuario> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = bytesDaFoto(widget.foto);
  }

  @override
  void didUpdateWidget(AvatarUsuario antigo) {
    super.didUpdateWidget(antigo);
    // decodifica só quando a foto muda, para a imagem não piscar a cada reconstrução
    if (antigo.foto != widget.foto) _bytes = bytesDaFoto(widget.foto);
  }

  @override
  Widget build(BuildContext context) {
    final lado = widget.raio * 2;
    final iniciais = Text(
      widget.iniciais,
      style: TextStyle(color: widget.corTexto, fontSize: widget.raio * 0.78, fontWeight: FontWeight.w700, height: 1.0),
      maxLines: 1,
      overflow: TextOverflow.clip,
      softWrap: false,
    );
    final bytes = _bytes;
    return Container(
      width: lado,
      height: lado,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: widget.fundo, shape: BoxShape.circle),
      child: bytes == null
          ? iniciais
          : Image.memory(
              bytes,
              key: const Key('avatar-foto'),
              width: lado,
              height: lado,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, erro, pilha) => iniciais,
            ),
    );
  }
}
