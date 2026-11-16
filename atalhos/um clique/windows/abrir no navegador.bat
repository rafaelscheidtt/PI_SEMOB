@echo off
rem DashMOB - um clique: sobe a API e abre o app no navegador deste computador.
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
echo == baixando os pacotes do app
call flutter pub get
if errorlevel 1 goto erro
echo == compilando o app, leva cerca de 1 minuto
call flutter build web --release --dart-define=API_URL=http://localhost:8000
if errorlevel 1 goto plano_b
echo.
echo == DashMOB em http://localhost:8080   API em http://localhost:8000/docs
echo == feche esta janela e a janela "DashMOB API" para encerrar
echo.
start "" /min cmd /c "timeout /t 3 /nobreak >nul && start http://localhost:8080"
"..\backend\.venv\Scripts\python.exe" -m http.server 8080 --bind 127.0.0.1 --directory build\web
pause
exit /b 0

:plano_b
echo.
echo == a compilacao falhou; tentando servir direto pelo Flutter
echo == abra http://localhost:8080 no navegador quando aparecer "is being served"
call flutter run -d web-server --web-port 8080 --dart-define=API_URL=http://localhost:8000
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
echo Deu erro. Manda um print desta janela no grupo.
pause
exit /b 1
