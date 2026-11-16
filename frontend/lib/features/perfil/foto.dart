import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

/// Lado, em pixels, da foto guardada no perfil. Pequena de propósito: ela vai dentro do cadastro do usuário.
const ladoDaFoto = 160;

/// Devolve a foto escolhida como data URL, ou `null` se o usuário desistiu.
typedef EscolherFoto = Future<String?> Function();

/// Abre o seletor de imagens do aparelho e devolve a foto recortada em quadrado e reduzida.
Future<String?> escolherFotoDoAparelho() async {
  final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
  final bytes = r == null || r.files.isEmpty ? null : r.files.first.bytes;
  if (bytes == null) return null;
  return prepararFoto(bytes);
}

/// Recorta o centro da imagem em quadrado, reduz para [ladoDaFoto] e devolve como data URL em PNG.
Future<String> prepararFoto(Uint8List original) async {
  final ui.Image imagem;
  try {
    final codec = await ui.instantiateImageCodec(original);
    imagem = (await codec.getNextFrame()).image;
  } catch (_) {
    throw const FormatException('Não foi possível abrir essa imagem. Use um arquivo PNG ou JPG.');
  }
  final largura = imagem.width.toDouble();
  final altura = imagem.height.toDouble();
  final lado = largura < altura ? largura : altura;
  final origem = ui.Rect.fromLTWH((largura - lado) / 2, (altura - lado) / 2, lado, lado);
  final destino = ui.Rect.fromLTWH(0, 0, ladoDaFoto.toDouble(), ladoDaFoto.toDouble());

  final gravador = ui.PictureRecorder();
  ui.Canvas(gravador).drawImageRect(imagem, origem, destino, ui.Paint()..filterQuality = ui.FilterQuality.high);
  final reduzida = await gravador.endRecording().toImage(ladoDaFoto, ladoDaFoto);
  final png = await reduzida.toByteData(format: ui.ImageByteFormat.png);
  imagem.dispose();
  reduzida.dispose();
  if (png == null) throw const FormatException('Não foi possível preparar a foto.');
  return 'data:image/png;base64,${base64Encode(png.buffer.asUint8List())}';
}
