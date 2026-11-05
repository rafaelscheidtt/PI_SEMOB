@echo off
rem DashMOB - um clique: sobe a API e o app liberados pra rede Wi-Fi e mostra o QR code
rem pra abrir no celular (o celular precisa estar na MESMA rede Wi-Fi deste computador).
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
".venv\Scripts\python.exe" -m pip install -q -r requirements.txt qrcode
if errorlevel 1 goto erro

if not exist ".env" (
  > ".env" echo MONGODB_URL=COLE_AQUI_A_URL_QUE_O_GUILHERME_MANDOU
  >> ".env" echo MONGODB_DB=dashmob
  >> ".env" echo CORS_ORIGINS=*
)
findstr /c:"COLE_AQUI" ".env" >nul && goto configurar_env

rem endereco deste computador na rede Wi-Fi
set "IP="
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1).IPv4Address.IPAddress"`) do set "IP=%%i"
if "%IP%"=="" (
  echo Nao achei o endereco deste computador na rede. Conecte no Wi-Fi e tente de novo.
  pause
  exit /b 1
)

rem API numa janela separada, aberta pra rede (feche a janela "DashMOB API" para parar)
start "DashMOB API" cmd /k ".venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000"

cd /d "%~dp0..\..\..\frontend"
where flutter >nul 2>nul
if errorlevel 1 goto sem_flutter
echo == baixando os pacotes do app
call flutter pub get
if errorlevel 1 goto erro
echo == compilando o app, leva cerca de 1 minuto
call flutter build web --release --dart-define=API_URL=http://%IP%:8000
if errorlevel 1 goto erro
cls
echo == DashMOB no celular: aponte a camera pro QR code ou digite  http://%IP%:8080
echo == (se o Windows perguntar se o python pode receber conexoes, clique em Permitir acesso)
echo.
"..\backend\.venv\Scripts\python.exe" -c "import sys,qrcode; q=qrcode.QRCode(border=1); q.add_data(sys.argv[1]); q.make(); q.print_ascii(invert=True)" "http://%IP%:8080"
echo.
echo == no Chrome do celular da pra usar "Adicionar a tela inicial" e virar icone de app
echo == feche esta janela e a janela "DashMOB API" para encerrar
"..\backend\.venv\Scripts\python.exe" -m http.server 8080 --bind 0.0.0.0 --directory build\web
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
