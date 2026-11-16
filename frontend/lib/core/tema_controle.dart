import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';

/// Modo claro/escuro escolhido pelo usuário, guardado no aparelho.
class ControleTema extends ValueNotifier<ThemeMode> {
  ControleTema({ThemeMode inicial = ThemeMode.light, this.persistir = true}) : super(inicial) {
    Cores.aplicar(inicial);
  }

  static const _chave = 'dashmob.tema';

  final bool persistir;

  bool get escuro => value == ThemeMode.dark;

  Future<void> carregar() async {
    if (!persistir) return;
    try {
      final guardado = (await SharedPreferences.getInstance()).getString(_chave);
      if (guardado == 'escuro') _definir(ThemeMode.dark);
    } catch (_) {
      // sem preferência guardada: fica no claro
    }
  }

  Future<void> alternar() => definir(escuro ? ThemeMode.light : ThemeMode.dark);

  Future<void> definir(ThemeMode modo) async {
    _definir(modo);
    if (!persistir) return;
    try {
      await (await SharedPreferences.getInstance()).setString(_chave, modo == ThemeMode.dark ? 'escuro' : 'claro');
    } catch (_) {
      // não conseguiu guardar: vale só nesta sessão
    }
  }

  void _definir(ThemeMode modo) {
    Cores.aplicar(modo);
    value = modo;
  }
}
