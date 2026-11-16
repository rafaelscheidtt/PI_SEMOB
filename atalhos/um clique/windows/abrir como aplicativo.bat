@echo off
rem DashMOB - um clique: sobe a API e abre o DashMOB como aplicativo de computador (janela propria, sem navegador).
rem Precisa do Visual Studio com "Desenvolvimento para desktop com C++". Duvida: rode "flutter doctor".
setlocal
cd /d "%~dp0..\..\..\backend"

where py >nul 2>nul
if %errorlevel%==0 (set "PY=py -3") else (set "PY=python")

if not exist ".venv\Scripts\python.exe" (
  echo == criando o ambiente virtual do Python
  %PY% -m venv .venv
  if errorlevel 1 goto sem_python
)
echo == preparando a API
".venv\Scripts\python.exe" -m pip install -q -r requirements.txt
if errorlevel 1 goto erro

if not exist ".env" (
  > ".env" echo MONGODB_URL=COLE_AQUI_A_URL_QUE_O_GUILHERME_MANDOU
  >> ".env" echo MONGODB_DB=dashmob
  >> ".env" echo CORS_ORIGINS=*
)
findstr /c:"COLE_AQUI" ".env" >nul && goto configurar_env

rem API numa janela separada (feche a janela "DashMOB API" para parar)
start "DashMOB API" cmd /k ".venv\Scripts\python.exe -m uvicorn app.main:app --port 8000"

cd /d "%~dp0..\..\..\frontend"
where flutter >nul 2>nul
if errorlevel 1 goto sem_flutter
rem a pasta do aplicativo de Windows e criada na primeira vez
if not exist "windows" (
  echo == preparando o projeto para Windows
  call flutter create --platforms=windows --project-name dashmob --org br.gov.sp.saocaetano.semob .
  if errorlevel 1 goto erro
)
echo == baixando os pacotes do app
call flutter pub get
if errorlevel 1 goto erro
echo == montando e abrindo o aplicativo, a primeira vez demora alguns minutos
echo == feche a janela do DashMOB, esta janela e a janela "DashMOB API" para encerrar
call flutter run --release -d windows --dart-define=API_URL=http://localhost:8000
if errorlevel 1 goto erro
pause
exit /b 0

:configurar_env
echo.
echo Falta configurar o banco. Vai abrir o arquivo backend\.env no Bloco de Notas:
echo troque a primeira linha pela MONGODB_URL que o Guilherme mandou, salve,
echo feche o Bloco de Notas e rode este atalho de novo.
notepad ".env"
pause
exit /b 1

:sem_python
echo.
echo Nao achei o Python. Instale o Python 3.12 pelo python.org e marque a opcao
echo "Add python.exe to PATH" na instalacao. Depois rode este atalho de novo.
pause
exit /b 1

:sem_flutter
echo.
echo Nao achei o Flutter. Instale pelo docs.flutter.dev e confira com "flutter doctor".
pause
exit /b 1

:erro
echo.
echo Deu erro. Rode "flutter doctor" pra ver o que falta e manda um print desta janela no grupo.
pause
exit /b 1
