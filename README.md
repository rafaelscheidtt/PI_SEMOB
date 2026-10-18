# DashMOB

Painel de operação do transporte municipal de São Caetano do Sul, feito para a SEMOB-SCS
(Secretaria de Mobilidade Urbana) no Projeto Integrador (TTI206) do Instituto Mauá de
Tecnologia, 2º semestre de 2026.

A SEMOB recebe da Smart Data relatórios em HTML com a operação dos ônibus. O DashMOB importa
esses relatórios e mostra quilometragem, viagens programadas e realizadas, cumprimento de
viagens, passageiros (pagantes e gratuidades) e ocorrências, por dia, semana ou mês e por linha.

## Estrutura

```
backend/    API em Python (FastAPI) com MongoDB
frontend/   app em Flutter (web, desktop e mobile)
dados/      relatórios da SEMOB (semob/) e um pacote fictício para os testes (exemplo/)
scripts/    scripts de apoio (setup, geração do pacote de exemplo)
docs/       evidências de testes
```

O app só conversa com a API, e só a API acessa o banco.

## Como rodar

### API

Precisa de um MongoDB. A gente usa o Atlas (a string de conexão vai no `.env`); quem
preferir rodar local pode usar o `docker-compose.yml` da pasta `backend`.

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env      # colocar a MONGODB_URL
uvicorn app.main:app --reload
```

A documentação das rotas fica em http://localhost:8000/docs.

Para importar os relatórios (pasta, `.zip` ou arquivos `.html`):

```bash
python -m app.cli ../dados/semob/Agosto_2026/Mensal
```

### App

Com a API rodando:

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_URL=http://localhost:8000
```

## Relatórios importados

Cada arquivo é reconhecido pelo título do relatório.

| Relatório | O que traz | Coleção |
|-----------|------------|---------|
| Resumo Geral | veículos, viagens programadas/realizadas e km por dia | `operacao_diaria` |
| Fator de Cumprimento de Viagem | programadas e realizadas por turno | `operacao_diaria` |
| Resumo por Faixa Horária | viagens e veículos por hora | `operacao_diaria` |
| Passageiros do Sistema | catraca, antecipados e não pagantes por dia | `operacao_diaria` |
| Saldos / Venda x Utilização | créditos de bilhetagem por dia | `operacao_diaria` |
| Resumo por Linha | km e viagens por linha | `operacao_linha_diaria` |
| Partidas por Faixa Horária | partidas por linha e hora | `operacao_linha_diaria` |
| Viagens não realizadas, não iniciadas e não terminadas | uma ocorrência por viagem | `ocorrencias_viagem` |
| Viagens | cada viagem realizada | `viagens` |

Os passageiros vêm da bilhetagem do sistema todo, então não existem por linha. O código do
motorista que aparece nos relatórios de ocorrência não é gravado no banco.

## Rotas principais

| Rota | Para que serve |
|------|----------------|
| `POST /importacoes` | importa um ou mais relatórios (ou o `.zip`) |
| `GET /importacoes` | histórico de importações |
| `GET /indicadores` | série e totais do período (`inicio`, `fim`, `granularidade`, `linha`, `comparar`) |
| `GET /indicadores/linhas` | km, viagens e ocorrências por linha |
| `GET /ocorrencias` | lista de ocorrências de viagem |
| `GET /linhas` | linhas cadastradas |

## Testes

```bash
cd backend && pytest --cov=app
cd frontend && flutter test --coverage
```

O nome de cada teste começa com a história ou a regra que ele cobre (`test_us01_...`,
`test_rn04_...`). Os cenários em Gherkin das histórias estão em `frontend/test/features/`.

## Fluxo de trabalho

Usamos Git Flow: `main` tem a versão apresentada à SEMOB, `develop` junta o trabalho da sprint
e cada história é feita numa branch `feature/USxx-...`, que entra em `develop` por pull request
revisado por outra pessoa do grupo. Os commits seguem o Conventional Commits, com a história
no escopo (ex.: `feat(US02): ...`).

## Equipe

| Nome | R.A. | GitHub |
|------|------|--------|
| Luigi Battistini (PO) | 25.01439-0 | |
| Matheus Anderson Moraes (Scrum Master) | 25.01481-2 | |
| Rafael Scheidt Reschke | 25.00356-7 | [@rafaelscheidtt](https://github.com/rafaelscheidtt) |
| Thales Xavier von Tein | 25.01250-1 | |
| Mateo Vuolo Cortez | 24.00775-7 | [@omateocortez](https://github.com/omateocortez) |
| Guilherme Tomaz Gomes | 24.00520-7 | [@guit953](https://github.com/guit953) |
