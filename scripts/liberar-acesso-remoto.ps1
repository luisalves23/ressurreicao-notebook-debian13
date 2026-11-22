<#
  liberar-acesso-remoto.ps1
  Roda NO PC DO SEGUIDOR, em PowerShell aberto COMO ADMINISTRADOR.
  Libera o acesso pela rede local (WinRM / PowerShell Remoting) para que a
  estacao de trabalho consiga fazer o diagnostico e a manutencao.

  Liberar:  powershell -ExecutionPolicy Bypass -File .\liberar-acesso-remoto.ps1
  Desfazer: powershell -ExecutionPolicy Bypass -File .\liberar-acesso-remoto.ps1 -Desfazer

  O que ele muda (e o -Desfazer reverte):
   1. Perfil da rede Wi-Fi atual -> Privada (Windows 8+)
   2. Liga o servico WinRM e o PowerShell Remoting
   3. Firewall: libera ping e WinRM (porta 5985) SOMENTE para a rede local
   4. Permite que contas locais de administrador sejam usadas pela rede
#>
param([switch]$Desfazer)

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Write-Host 'ABRA O POWERSHELL COMO ADMINISTRADOR e rode de novo.' -ForegroundColor Red; exit 1 }

$chave = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'

if ($Desfazer) {
    Disable-PSRemoting -Force
    Stop-Service WinRM; Set-Service WinRM -StartupType Manual
    netsh advfirewall firewall delete rule name="PC-Seguidor WinRM" | Out-Null
    netsh advfirewall firewall delete rule name="PC-Seguidor Ping"  | Out-Null
    Remove-ItemProperty -Path $chave -Name LocalAccountTokenFilterPolicy -ErrorAction SilentlyContinue
    Write-Host 'Acesso remoto DESFEITO.' -ForegroundColor Green
    exit 0
}

# 1. Rede como Privada (Windows 8 em diante)
if (Get-Command Set-NetConnectionProfile -ErrorAction SilentlyContinue) {
    Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -ne 'DomainAuthenticated' } | Set-NetConnectionProfile -NetworkCategory Private
} else {
    Write-Host 'Windows 7: se aparecer erro de rede Publica, marque a rede como "Rede doméstica" na Central de Rede.' -ForegroundColor Yellow
}

# 2. WinRM / PowerShell Remoting
Enable-PSRemoting -Force
Set-Service WinRM -StartupType Automatic

# 3. Firewall restrito a rede local
netsh advfirewall firewall add rule name="PC-Seguidor WinRM" dir=in action=allow protocol=TCP localport=5985 remoteip=localsubnet | Out-Null
netsh advfirewall firewall add rule name="PC-Seguidor Ping"  dir=in action=allow protocol=icmpv4:8,any remoteip=localsubnet | Out-Null

# 4. Contas locais de admin pela rede
New-ItemProperty -Path $chave -Name LocalAccountTokenFilterPolicy -Value 1 -PropertyType DWord -Force | Out-Null

# Resumo para passar para a estacao
$ips = (Get-WmiObject Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True' | ForEach-Object { $_.IPAddress } | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' }) -join ', '
$semSenha = $false
try { $u = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True AND Name='$env:USERNAME'"; $semSenha = -not $u.PasswordRequired } catch {}

Write-Host ''
Write-Host '================ ACESSO LIBERADO ================' -ForegroundColor Green
Write-Host "  Nome do PC : $env:COMPUTERNAME"
Write-Host "  IP         : $ips"
Write-Host "  Usuario    : $env:COMPUTERNAME\$env:USERNAME"
if ($semSenha) { Write-Host '  ATENCAO: este usuario NAO tem senha. O acesso remoto exige senha; crie uma temporaria.' -ForegroundColor Yellow }
Write-Host '================================================='
