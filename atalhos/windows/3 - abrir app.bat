@echo off
rem DashMOB - atalho para Windows: compila o app e abre no navegador. Antes, deixe o "2 - subir API" rodando.
setlocal
cd /d "%~dp0..\..\frontend"
where flutter >nul 2>nul
if errorlevel 1 goto sem_flutter

rem usa o Python do back-end (criado pelo "2 - subir API") para servir o app
set "PY=..\backend\.venv\Scripts\python.exe"
if not exist "%PY%" (
  where py >nul 2>nul
  if not errorlevel 1 (set "PY=py -3") else (set "PY=python")
)

echo == baixando os pacotes do app
call flutter pub get
if errorlevel 1 goto erro

echo == compilando o app, leva cerca de 1 minuto
call flutter build web --release --dart-define=API_URL=http://localhost:8000
if errorlevel 1 goto erro

echo.
echo == DashMOB em http://localhost:8080  (feche esta janela para encerrar)
echo.
start "" /min cmd /c "timeout /t 3 /nobreak >nul && start http://localhost:8080"
%PY% -m http.server 8080 --bind 127.0.0.1 --directory build\web
pause
exit /b 0

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
