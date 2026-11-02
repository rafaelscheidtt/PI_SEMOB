/// Configuração do aplicativo, lida em tempo de compilação:
/// `flutter run --dart-define=API_URL=http://localhost:8000`
class Config {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');
}
