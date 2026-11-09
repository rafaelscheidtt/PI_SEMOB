import 'package:flutter/material.dart';

/// Cores que mudam entre o modo claro e o escuro: fundo, cartões, linhas, textos e os tons suaves
/// das etiquetas. As cores de marca (navy, verde, vermelho...) ficam iguais nos dois modos.
class Paleta {
  const Paleta({
    required this.fundo,
    required this.superficie,
    required this.linha,
    required this.tinta,
    required this.texto2,
    required this.verdeSuave,
    required this.vermelhoSuave,
    required this.ambarSuave,
    required this.azulSuave,
    required this.azul,
    required this.destaque,
    required this.sobreDestaque,
    required this.escura,
  });

  final Color fundo;
  final Color superficie;
  final Color linha;
  final Color tinta;
  final Color texto2;
  final Color verdeSuave;
  final Color vermelhoSuave;
  final Color ambarSuave;
  final Color azulSuave;

  /// Azul de informação (etiquetas, avisos); mais claro no modo escuro para ter contraste.
  final Color azul;

  /// Cor principal dos dados (colunas, sparklines, segmento selecionado): navy no claro, azul-claro no escuro.
  final Color destaque;

  /// Texto em cima de [destaque].
  final Color sobreDestaque;
  final bool escura;

  /// As cores do protótipo no Figma.
  static const clara = Paleta(
    fundo: Color(0xFFF5F6FA),
    superficie: Colors.white,
    linha: Color(0xFFE6E8EF),
    tinta: Color(0xFF1B1F2E),
    texto2: Color(0xFF6B7280),
    verdeSuave: Color(0xFFE3F4EE),
    vermelhoSuave: Color(0xFFFBE9E7),
    ambarSuave: Color(0xFFFBF1DC),
    azulSuave: Color(0xFFE6ECFA),
    azul: Color(0xFF2F4FB5),
    destaque: Color(0xFF181949),
    sobreDestaque: Colors.white,
    escura: false,
  );

  /// Modo escuro: mesmos azuis do menu, fundo quase preto e texto claro.
  static const escuro = Paleta(
    fundo: Color(0xFF0F1124),
    superficie: Color(0xFF1A1C38),
    linha: Color(0xFF2E3158),
    tinta: Color(0xFFEDEFF8),
    texto2: Color(0xFFA3A7C9),
    verdeSuave: Color(0xFF123A30),
    vermelhoSuave: Color(0xFF42201F),
    ambarSuave: Color(0xFF3F3114),
    azulSuave: Color(0xFF1E2A52),
    azul: Color(0xFF9AA5F0),
    destaque: Color(0xFF8FA3FF),
    sobreDestaque: Color(0xFF0F1124),
    escura: true,
  );
}

/// Cores do painel. As de marca são constantes; as de superfície e texto vêm da [Paleta]
/// em uso, trocada por [aplicar] quando o usuário alterna o modo escuro (o app inteiro é
/// reconstruído em seguida, então todos os widgets pegam a paleta nova).
class Cores {
  Cores._();

  static Paleta paleta = Paleta.clara;

  static void aplicar(ThemeMode modo) => paleta = modo == ThemeMode.dark ? Paleta.escuro : Paleta.clara;

  // marca (iguais nos dois modos)
  static const navy = Color(0xFF181949);
  static const navyClaro = Color(0xFF283474); // azul do brasão da Prefeitura
  static const verde = Color(0xFF0F8F6B);
  static const vermelho = Color(0xFFC62828);
  static const ambar = Color(0xFFB7791F);

  // superfícies e textos (mudam com o modo)
  static Color get fundo => paleta.fundo;
  static Color get superficie => paleta.superficie;
  static Color get linha => paleta.linha;
  static Color get tinta => paleta.tinta;
  static Color get texto2 => paleta.texto2;
  static Color get verdeSuave => paleta.verdeSuave;
  static Color get vermelhoSuave => paleta.vermelhoSuave;
  static Color get ambarSuave => paleta.ambarSuave;
  static Color get azulSuave => paleta.azulSuave;
  static Color get azul => paleta.azul;
  static Color get destaque => paleta.destaque;
  static Color get sobreDestaque => paleta.sobreDestaque;

  // menu lateral (sempre escuro)
  static const menuTexto = Color(0xFFC9CBE3);
  static const menuApagado = Color(0xFF6F73A3);
  static const menuTitulo = Color(0xFF8A8EB8);
  static const menuEtiqueta = Color(0xFF2C2E6B);
}

ThemeData temaDashMob() => _tema(Paleta.clara);

ThemeData temaDashMobEscuro() => _tema(Paleta.escuro);

ThemeData _tema(Paleta p) {
  final brilho = p.escura ? Brightness.dark : Brightness.light;
  final esquema = ColorScheme.fromSeed(seedColor: Cores.navy, brightness: brilho).copyWith(
    primary: p.destaque,
    onPrimary: p.sobreDestaque,
    secondary: Cores.verde,
    surface: p.superficie,
    onSurface: p.tinta,
    outline: p.linha,
    error: Cores.vermelho,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    colorScheme: esquema,
    scaffoldBackgroundColor: p.fundo,
    canvasColor: p.superficie,
    cardColor: p.superficie,
    dividerColor: p.linha,
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontSize: 14, color: p.tinta, height: 1.45),
      bodySmall: TextStyle(fontSize: 12.5, color: p.texto2),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.tinta),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.tinta),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.tinta),
    ),
  );
}
