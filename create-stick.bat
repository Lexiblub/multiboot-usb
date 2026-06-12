@echo off
title Create Multiboot Stick
echo ==============================================
echo   Multiboot USB Toolkit
echo   Prerequisite: Ventoy is on the stick
echo   (one time via Ventoy2Disk.exe, see README)
echo ==============================================
echo.
set /p D=Drive letter of the Ventoy stick (e.g. E):
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-stick.ps1" -Drive %D%:
echo.
pause
