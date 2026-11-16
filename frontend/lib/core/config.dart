/// Configuração lida em tempo de compilação (--dart-define=API_URL=...).
class Config {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');
}
