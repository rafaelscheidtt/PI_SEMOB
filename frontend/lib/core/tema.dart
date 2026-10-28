import 'package:flutter/material.dart';

/// Cores do painel, as mesmas do protótipo no Figma.
class Cores {
  Cores._();

  static const navy = Color(0xFF181949);
  static const navyClaro = Color(0xFF232560);
  static const fundo = Color(0xFFF5F6FA);
  static const linha = Color(0xFFE6E8EF);
  static const tinta = Color(0xFF1B1F2E);
  static const texto2 = Color(0xFF6B7280);
  static const verde = Color(0xFF0F8F6B);
  static const verdeSuave = Color(0xFFE3F4EE);
  static const vermelho = Color(0xFFC62828);
  static const vermelhoSuave = Color(0xFFFBE9E7);
  static const ambar = Color(0xFFB7791F);
  static const ambarSuave = Color(0xFFFBF1DC);
  static const azul = Color(0xFF2F4FB5);
  static const azulSuave = Color(0xFFE6ECFA);

  // menu lateral
  static const menuTexto = Color(0xFFC9CBE3);
  static const menuApagado = Color(0xFF6F73A3);
  static const menuTitulo = Color(0xFF8A8EB8);
  static const menuEtiqueta = Color(0xFF2C2E6B);
}

ThemeData temaDashMob() {
  final esquema = ColorScheme.fromSeed(seedColor: Cores.navy).copyWith(
    primary: Cores.navy,
    onPrimary: Colors.white,
    secondary: Cores.verde,
    surface: Colors.white,
    onSurface: Cores.tinta,
    outline: Cores.linha,
    error: Cores.vermelho,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Cores.fundo,
    dividerColor: Cores.linha,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 14, color: Cores.tinta, height: 1.45),
      bodySmall: TextStyle(fontSize: 12.5, color: Cores.texto2),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Cores.tinta),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Cores.tinta),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Cores.tinta),
    ),
  );
}
