@echo off
set "TARGET=%ProgramFiles%\ScilabReserve"
if not exist "%TARGET%" mkdir "%TARGET%"
xcopy /E /I /Y "%~dp0*" "%TARGET%" >nul
start "" "%TARGET%\admin_scalib.exe"
