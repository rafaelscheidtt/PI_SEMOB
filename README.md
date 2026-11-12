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

### Atalhos (Mac e Windows)

Na pasta `atalhos/` tem os mesmos atalhos em duas versões: `atalhos/mac/` (arquivos `.command`)
e `atalhos/windows/` (arquivos `.bat`). É só clicar duas vezes no da sua máquina:

| Atalho | O que faz |
|--------|-----------|
| `1 - rodar testes` | roda os testes da API e do app |
| `2 - subir API` | prepara o Python e sobe a API em http://localhost:8000/docs (deixe a janela aberta) |
| `3 - abrir app` | abre o app no navegador, com a API já rodando |
| `4 - importar relatorios` | importa os relatórios de `dados/semob` (só quando chegarem relatórios novos) |

Pra demonstrar, tem ainda a pasta `atalhos/um clique/` (também com `mac/` e `windows/`), que sobe a API
e o app de uma vez: `abrir no navegador` abre o DashMOB no computador e `abrir no celular` mostra um
QR code pra abrir no celular, que precisa estar na mesma rede Wi-Fi.

Na primeira vez, o `2 - subir API` cria o `backend/.env` e abre ele para colar a `MONGODB_URL`
do Atlas, que a gente passa no privado. Precisa ter Python 3.12 e Flutter instalados. No Mac, se
aparecer aviso de desenvolvedor não identificado, clique com o botão direito no atalho e em Abrir.

Se preferir o terminal, os passos são estes:

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

### Login e usuários

O painel pede login (US11). Ninguém se cadastra sozinho: o primeiro administrador é criado uma
vez só, por quem sobe a API — ou pelo `.env` (`ADMIN_INICIAL_EMAIL` e `ADMIN_INICIAL_SENHA`,
usados só se ainda não existir nenhum usuário) ou pela linha de comando:

```bash
python -m app.usuarios_cli criar-admin "Nome" email@semob.gov.br
```

Daí em diante é o administrador que cadastra os outros, na tela Usuários do app, escolhendo o
papel de cada um:

| Papel | O que enxerga |
|-------|---------------|
| administrador | tudo, mais a tela Usuários |
| gestor | o painel completo e a importação de relatórios |
| executivo | só a visão resumida: Visão Geral, Cumprimento de viagens e Passageiros |

Como o banco do Atlas é um só pra todo o grupo, o administrador criado por uma pessoa vale pra
todas. Com o token em mãos (resposta do `POST /login`), o botão Authorize do `/docs` libera as
outras rotas. O segredo que assina os tokens e a validade da sessão ficam no `.env`
(`TOKEN_SECRET`, `TOKEN_HORAS`).

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

## Telas

O app segue o protótipo do Figma: menu lateral (recolhido, abre ao passar o mouse), barra de filtros
(intervalo e linha, que valem para todas as telas) e as telas abaixo. A visão diária, semanal ou mensal
fica em cima dos gráficos de cada tela, porque só eles mudam com ela. Tem modo escuro, no botão de lua
do rodapé do menu (a escolha fica guardada no aparelho).

| Tela | O que mostra |
|------|--------------|
| Visão Geral | km, viagens, passageiros e gratuidades com a variação em relação ao período anterior, pagantes × gratuidades, cumprimento por turno, viagens por faixa horária e a tabela de monitoramento por linha |
| Monitoramento | tela para TV: seis números grandes (km, viagens, cumprimento, passageiros, gratuidades e viagens não realizadas) com a variação, mais o cumprimento por turno; atualiza sozinha a cada 5 minutos |
| Linhas | a mesma tabela com busca e, ao clicar, o detalhamento da linha: indicadores, faixa horária e ocorrências de viagem |
| Cumprimento de viagens | FCV do período, por turno e ao longo do tempo, com os períodos em que faltaram mais viagens |
| Passageiros | pagantes, gratuidades, total e média por viagem (sempre do sistema inteiro) |
| Importação de relatórios | envio do pacote (HTML ou .zip) e histórico do que já foi importado (gestor e administrador) |
| Financeiro | vendas, utilização, crédito circulante e saldo de créditos da bilhetagem, em reais, com o aviso do Tarifa Zero para períodos sem bilhetagem |
| Usuários | cadastro, papel e desativação de usuários (só o administrador) |

Alertas e Relatórios aparecem no menu marcadas como Sprint 2.

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

Fora `/login` e `/health`, todas pedem o cabeçalho `Authorization: Bearer <token>`.

| Rota | Para que serve |
|------|----------------|
| `POST /login` | e-mail e senha; devolve o token e o papel do usuário |
| `GET /me` | usuário da sessão atual |
| `GET /usuarios`, `POST /usuarios`, `PUT /usuarios/{id}` | cadastro de usuários (só administrador) |
| `POST /importacoes` | importa um ou mais relatórios (ou o `.zip`); gestor e administrador |
| `GET /importacoes` | histórico de importações |
| `GET /indicadores` | série e totais do período (`inicio`, `fim`, `granularidade`, `linha`, `comparar`) |
| `GET /indicadores/linhas` | km, viagens e ocorrências por linha |
| `GET /indicadores/detalhes` | cumprimento por turno e viagens por faixa horária (`inicio`, `fim`, `linha`) |
| `GET /indicadores/financeiro` | vendas, utilização, crédito circulante e saldo de créditos por período (`inicio`, `fim`, `granularidade`, `comparar`) |
| `GET /alertas` | dias fora do padrão: cumprimento baixo, desvio do histórico e excesso de ocorrências (`inicio`, `fim`, `linha`) |
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
