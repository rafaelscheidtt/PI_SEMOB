@echo off
rem DashMOB - um clique: instala o aplicativo de verdade no celular Android ligado no cabo
rem e sobe a API liberada pra rede Wi-Fi. O celular precisa estar na MESMA rede Wi-Fi deste computador.
rem Antes da primeira vez: ligar "Opcoes do desenvolvedor" e "Depuracao USB" no celular e ter o
rem Android Studio instalado. iPhone so da pra instalar a partir de um Mac.
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

rem endereco deste computador na rede Wi-Fi (e pra onde o app do celular vai ligar)
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

echo == procurando o celular
set "APARELHO="
call flutter devices --machine > "%TEMP%\dashmob_aparelhos.json" 2>nul
for /f "usebackq delims=" %%i in (`"..\backend\.venv\Scripts\python.exe" "..\scripts\primeiro_celular.py" "%TEMP%\dashmob_aparelhos.json" android`) do set "APARELHO=%%i"
del "%TEMP%\dashmob_aparelhos.json" >nul 2>nul
if "%APARELHO%"=="" (
  echo.
  echo Nao achei nenhum celular Android. Confira se o cabo esta ligado, o celular desbloqueado,
  echo a Depuracao USB ligada e o aviso "Permitir depuracao" aceito.
  call flutter devices
  pause
  exit /b 1
)

echo == instalando no celular, a primeira vez demora alguns minutos
echo == a API fica em http://%IP%:8000 ; feche esta janela e a janela "DashMOB API" para encerrar
call flutter run --release -d %APARELHO% --dart-define=API_URL=http://%IP%:8000
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
