@echo off
rem DashMOB - atalho para Windows: roda os testes da API e do app.
setlocal
cd /d "%~dp0..\..\backend"

where py >nul 2>nul
if %errorlevel%==0 (set "PY=py -3") else (set "PY=python")

if not exist ".venv\Scripts\python.exe" (
  echo == criando o ambiente virtual do Python
  %PY% -m venv .venv
  if errorlevel 1 goto sem_python
)
call ".venv\Scripts\activate.bat"
echo == instalando dependencias, a primeira vez demora um pouco
python -m pip install -q --upgrade pip
python -m pip install -q -r requirements.txt
if errorlevel 1 goto erro

echo.
echo == testes da API
python -m pytest --cov=app
echo.
cd /d "%~dp0..\..\frontend"
where flutter >nul 2>nul
if errorlevel 1 goto sem_flutter
echo == testes do app
call flutter pub get
call flutter test
echo.
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
