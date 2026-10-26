@echo off
rem DashMOB - atalho para Windows: abre o app. Antes, deixe o "2 - subir API" rodando.
setlocal
cd /d "%~dp0..\..\frontend"
where flutter >nul 2>nul
if errorlevel 1 goto sem_flutter

echo == baixando os pacotes do app
call flutter pub get
if errorlevel 1 goto erro

echo.
echo == abrindo o app no Chrome, a primeira vez demora um pouco
echo == Para parar: tecle q nesta janela
echo.
call flutter run -d chrome --dart-define=API_URL=http://localhost:8000
if errorlevel 1 (
  echo.
  echo == nao deu no Chrome, tentando no Edge
  call flutter run -d edge --dart-define=API_URL=http://localhost:8000
)
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
