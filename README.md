# DashMOB

Painel de operação do transporte municipal de São Caetano do Sul, feito para a SEMOB-SCS
(Secretaria de Mobilidade Urbana) no Projeto Integrador (TTI206) do Instituto Mauá de
Tecnologia, 2º semestre de 2026.

A SEMOB recebe da Smart Data relatórios em HTML com a operação dos ônibus. O DashMOB importa
esses relatórios e mostra quilometragem, viagens programadas e realizadas, cumprimento de
viagens, passageiros (pagantes e gratuidades), bilhetagem e ocorrências, por dia, semana ou mês
e por linha, com alertas para os dias fora do padrão.

É um app só, em Flutter, que roda no navegador, como aplicativo de computador e como aplicativo
de celular (Android e iPhone). O passo a passo completo, com os problemas mais comuns, está em
[`docs/como-rodar.pdf`](docs/como-rodar.pdf).

## Estrutura

```
backend/    API em Python (FastAPI) com MongoDB
frontend/   app em Flutter (web, desktop e mobile)
atalhos/    atalhos de dois cliques para Mac e Windows (testes, API, app)
dados/      relatórios da SEMOB (semob/) e um pacote fictício para os testes (exemplo/)
scripts/    scripts de apoio (setup, geração do pacote de exemplo)
docs/       guia de como rodar e evidências de testes das duas sprints
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
e o app de uma vez. O mesmo código roda de vários jeitos:

| Atalho | Onde o app roda | O que precisa |
|--------|-----------------|---------------|
| `abrir no navegador` | navegador do computador | só o Flutter |
| `abrir no celular` | navegador do celular, pelo QR code | celular na mesma rede Wi-Fi |
| `instalar no celular (cabo)` | aplicativo instalado no Android ou no iPhone | celular no cabo e na mesma rede Wi-Fi; Android Studio (Android) ou Xcode num Mac (iPhone) |
| `abrir como aplicativo` | aplicativo de computador, em janela própria | Xcode (Mac) ou Visual Studio com C++ (Windows) |
| `abrir no simulador de iPhone` (só Mac) | aplicativo de iPhone, no Simulador do Xcode | Xcode; não precisa de cabo nem de conta da Apple |

No aplicativo instalado o endereço da API vai gravado na hora de montar, apontando para o computador
que rodou o atalho. Por isso ele só carrega com esse computador ligado, a janela do atalho aberta e os
dois na mesma rede Wi-Fi; mudou de rede, é só rodar o atalho de novo. Depois de instalado, o cabo pode
ser tirado. O `flutter doctor` mostra o que falta instalar para cada plataforma.

Para instalar em iPhone, na primeira vez: ligar o Modo de Desenvolvedor no aparelho (Ajustes >
Privacidade e Segurança) e escolher a sua conta Apple em `frontend/ios/Runner.xcworkspace` (Runner >
Signing & Capabilities > Team). Essa alteração do Xcode fica só na sua máquina, não entra em commit.
Com conta gratuita o app vale por 7 dias e depois é só instalar de novo.

No Mac, os atalhos que montam aplicativo copiam o `frontend` para `~/Library/Caches/dashmob` antes de
compilar. É de propósito: quando o projeto fica numa pasta sincronizada com o iCloud (Documentos, Mesa),
a assinatura da Apple falha com "resource fork, Finder information, or similar detritus not allowed".

Na primeira vez, o `2 - subir API` cria o `backend/.env` e abre ele para colar a `MONGODB_URL`
do Atlas, que a gente passa no privado. Precisa ter Python 3.12 e Flutter 3.47.5 instalados (é a
versão que o grupo usa e a que roda nos testes automáticos do GitHub). No Mac, se aparecer aviso de
desenvolvedor não identificado, clique com o botão direito no atalho e em Abrir.

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
| executivo | a Visão executiva (tela inicial) e as telas de indicadores; não importa relatórios, não vê o detalhe por linha e não cadastra ninguém |

No primeiro acesso, cada usuário lê e aceita o termo de uso e aviso de privacidade (veja
[Privacidade e LGPD](#privacidade-e-lgpd)). Depois, clicando no próprio nome no rodapé do menu, abre o
"Meu perfil", onde troca o nome, a foto e a senha; papel e e-mail continuam com o administrador.

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

O app partiu do protótipo do Figma: menu lateral, barra de filtros (intervalo e linha, que valem para
todas as telas) e as telas abaixo. A visão diária, semanal ou mensal fica em cima dos gráficos de cada
tela, porque só eles mudam com ela.

No computador o menu fica recolhido, só com os ícones, e abre ao passar o mouse, por cima do conteúdo;
o alfinete ao lado de "Operação" trava ele aberto. No celular o menu vira gaveta. Tem modo escuro, no
botão do rodapé do menu. As duas escolhas ficam guardadas no aparelho.

A identidade visual usa as cores do brasão de São Caetano do Sul em detalhes (o filete embaixo da barra
e a marca do item aberto no menu mudam conforme a tela), a fonte TeX Gyre Heros, uma versão livre da
Helvetica (`frontend/assets/fontes`, com a licença), e o logotipo "DASH | MOB". A foto de fundo do
login é do Palácio da Cerâmica, do site da Prefeitura.

| Tela | O que mostra |
|------|--------------|
| Visão Geral | km, viagens, passageiros e gratuidades com a variação em relação ao período anterior, pagantes × gratuidades, cumprimento por turno, viagens por faixa horária e a tabela de monitoramento por linha |
| Monitoramento | tela para TV: seis números grandes (km, viagens, cumprimento, passageiros, gratuidades e alertas críticos) com a variação, mais os alertas críticos em destaque e o cumprimento por turno; atualiza sozinha a cada 5 minutos |
| Linhas | a mesma tabela com busca e, ao clicar, o detalhamento da linha: indicadores, faixa horária e ocorrências de viagem |
| Cumprimento de viagens | FCV do período, por turno e ao longo do tempo, com os períodos em que faltaram mais viagens |
| Passageiros | pagantes, gratuidades, total e média por viagem (sempre do sistema inteiro) |
| Importação de relatórios | envio do pacote (HTML ou .zip) e histórico do que já foi importado (gestor e administrador) |
| Financeiro | vendas, utilização, crédito circulante e saldo de créditos da bilhetagem, em reais, com o aviso do Tarifa Zero para períodos sem bilhetagem |
| Alertas | dias fora do padrão: cumprimento abaixo de 95%/90% (RN09), desvio acima de 20%/35% do mesmo dia da semana nas últimas 8 semanas (RN10) e excesso de ocorrências (RN11); a Visão Geral mostra uma faixa com o total |
| Visão executiva | resumo para o secretário apresentar: seis destaques com a variação, comparativo com o período anterior e os alertas críticos; é a tela inicial do papel executivo |
| Relatórios | exporta o painel do período em PDF, com as seções escolhidas (indicadores, cumprimento, financeiro, alertas e linhas) |
| Usuários | cadastro, papel e desativação de usuários, com a foto de cada um (só o administrador) |
| Sobre o DashMOB | o que é o painel, como cada indicador é calculado, quando um alerta aparece, o que cada perfil acessa, privacidade e quem desenvolveu; abre pelo rodapé do menu, para todos os perfis |

Fora da lista do menu ficam o login, a tela do termo de uso (no primeiro acesso) e o "Meu perfil".
As telas não mostram os códigos das regras (RN) nem das histórias (US): as explicações para quem usa
estão na tela Sobre, e os códigos ficam só no código, nos testes e na documentação.

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

## Privacidade e LGPD

Do usuário o painel guarda nome, e-mail, perfil, situação da conta, o hash da senha, a data do aceite
do termo e, se a pessoa quiser, uma foto de perfil. A foto é reduzida no próprio app para 160 px e fica
dentro do cadastro do usuário, no MongoDB. Os indicadores são totais por dia e por linha: não
identificam passageiros, e o código do motorista dos relatórios de ocorrência não é gravado.

O texto do termo de uso e aviso de privacidade está em
`frontend/lib/features/legal/termo_texto.dart` e a versão em vigor em `TERMO_VERSAO`
(`backend/app/repositories/usuarios.py`). Mudou o texto, muda a versão nos dois lugares: no acesso
seguinte todo mundo é convidado a ler e aceitar de novo. O termo é um rascunho do grupo e precisa ser
validado pela SEMOB antes de uso real.

## Rotas principais

Fora `/login` e `/health`, todas pedem o cabeçalho `Authorization: Bearer <token>`.

| Rota | Para que serve |
|------|----------------|
| `POST /login` | e-mail e senha; devolve o token e o papel do usuário |
| `GET /me` | usuário da sessão atual |
| `PUT /me` | o próprio usuário muda nome, foto e senha |
| `POST /me/termo` | registra o aceite do termo de uso e aviso de privacidade (LGPD) |
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

Os mesmos testes rodam no GitHub a cada push em `develop` e `main` (`.github/workflows/ci.yml`),
junto com o `flutter analyze`, que reprova com qualquer aviso. A versão do Flutter fica fixa no
arquivo do CI: ao atualizar o Flutter do grupo, atualize lá também.

## Fluxo de trabalho

Usamos um Git Flow enxuto: `main` tem a versão apresentada à SEMOB e só recebe a `develop` por pull
request, com os testes do GitHub passando. A `develop` junta o trabalho da sprint: cada história entra
num commit de quem fez, depois de rodar o `1 - rodar testes` na própria máquina. Os commits seguem o
Conventional Commits, com a história no escopo (ex.: `feat(US02): ...`).

## Equipe

| Nome | R.A. | GitHub |
|------|------|--------|
| Luigi Battistini (PO) | 25.01439-0 | [@Battistinii](https://github.com/Battistinii) |
| Matheus Anderson Moraes (Scrum Master) | 25.01481-2 | [@matheusanderson18](https://github.com/matheusanderson18) |
| Rafael Scheidt Reschke | 25.00356-7 | [@rafaelscheidtt](https://github.com/rafaelscheidtt) |
| Thales Xavier von Tein | 25.01250-1 | [@thalesxvt](https://github.com/thalesxvt) |
| Mateo Vuolo Cortez | 24.00775-7 | [@omateocortez](https://github.com/omateocortez) |
| Guilherme Tomaz Gomes | 24.00520-7 | [@guit953](https://github.com/guit953) |
