import 'package:shared_preferences/shared_preferences.dart';

/// Lembra, no aparelho, se o usuário deixou o menu lateral travado aberto (US06).
class PreferenciaMenu {
  PreferenciaMenu._();

  static const _chave = 'dashmob.menuFixo';

  static Future<bool> ler() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_chave) ?? false;
    } catch (_) {
      return false; // sem preferência guardada: menu recolhido
    }
  }

  static Future<void> gravar(bool fixo) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_chave, fixo);
    } catch (_) {
      // não conseguiu guardar: vale só nesta sessão
    }
  }
}
