# DashMOB (app Flutter)

App do painel (web, desktop e mobile). Consome a API de `backend/`, ver o README da raiz.

```bash
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:8000
flutter test --coverage
```

Estrutura:

```
lib/core/       configuração, layout responsivo, períodos e formatação pt-BR
lib/data/       modelos e acesso à API
lib/features/   telas e componentes
test/unit/      testes unitários
test/widget/    testes de widget
test/features/  cenários BDD (Gherkin) das histórias
```
