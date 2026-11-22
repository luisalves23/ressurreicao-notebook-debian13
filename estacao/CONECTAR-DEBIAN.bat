@echo off
rem Clique duplo: prepara o acesso SSH do Claude ao notebook com Debian
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0conectar-debian.ps1"
