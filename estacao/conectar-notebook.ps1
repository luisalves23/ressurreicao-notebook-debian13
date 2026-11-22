<#
  conectar-notebook.ps1  (roda NESTA ESTACAO, como Administrador - use o .bat)
  1. Faz esta estacao confiar no IP do notebook (TrustedHosts do WinRM)
  2. Pede usuario/senha do notebook numa janela do Windows
  3. Guarda a credencial CRIPTOGRAFADA (DPAPI: so este usuario, neste PC abre)
     em %LOCALAPPDATA%\PC-Seguidor\notebook.cred  - FORA do repositorio Git
  4. Testa a conexao e mostra o resultado
#>
$ip  = '192.168.100.158'
$dir = Join-Path $env:LOCALAPPDATA 'PC-Seguidor'
New-Item -ItemType Directory -Force $dir | Out-Null
$log = Join-Path $dir 'conexao.log'   # sem senha; o Claude le este arquivo
function Write-Log([string]$t) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $t" | Out-File $log -Append -Encoding UTF8; Write-Host $t }

# O TrustedHosts so pode ser gravado com o servico WinRM ligado nesta estacao
try {
    Start-Service WinRM -ErrorAction Stop
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $ip -Force -ErrorAction Stop
    Write-Log "OK: estacao confia em $ip (TrustedHosts=$((Get-Item WSMan:\localhost\Client\TrustedHosts).Value))"
} catch {
    Write-Log "ERRO ao configurar TrustedHosts: $($_.Exception.Message)"
    Read-Host "`nEnter para fechar"; exit 1
}

$msg = "Usuario e senha do NOTEBOOK.`nConta local: digite  $ip\NomeDoUsuario`nConta Microsoft (e-mail): digite  MicrosoftAccount\seu@email.com"
$cred = Get-Credential -Message $msg -UserName "$ip\"
if (-not $cred) { Write-Host 'Cancelado.' -ForegroundColor Yellow; Read-Host 'Enter para fechar'; exit 1 }

try {
    Write-Log "Tentando conectar como usuario: $($cred.UserName)"
    $nome = Invoke-Command -ComputerName $ip -Credential $cred -ScriptBlock { "$env:COMPUTERNAME ($((Get-WmiObject Win32_OperatingSystem).Caption))" } -ErrorAction Stop
    $cred | Export-Clixml (Join-Path $dir 'notebook.cred')
    Write-Host ''
    Write-Log "CONECTADO com sucesso em: $nome"
    Write-Host 'Pode voltar para o Claude.' -ForegroundColor Green
} catch {
    Write-Host ''
    Write-Log "NAO conectou: $($_.Exception.Message)"
    Write-Host 'O Claude ja consegue ler este erro. Pode voltar para ele.' -ForegroundColor Red
}
Read-Host "`nEnter para fechar"
