@echo off
rem Clique duplo: abre como Administrador e roda conectar-notebook.ps1
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0conectar-notebook.ps1\"'"
