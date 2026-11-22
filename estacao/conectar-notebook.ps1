<#
  conectar-notebook.ps1  (roda NESTA ESTACAO, como Administrador - use o .bat)
  1. Faz esta estacao confiar no IP do notebook (TrustedHosts do WinRM)
  2. Pede usuario/senha do notebook numa janela do Windows
  3. Guarda a credencial CRIPTOGRAFADA (DPAPI: so este usuario, neste PC abre)
     em %LOCALAPPDATA%\PC-Seguidor\notebook.cred  - FORA do repositorio Git
  4. Testa a conexao e mostra o resultado
#>
$ip = '192.168.100.158'

Set-Item WSMan:\localhost\Client\TrustedHosts -Value $ip -Force
Write-Host "Esta estacao agora confia em $ip" -ForegroundColor Green

$msg = "Usuario e senha do NOTEBOOK.`nConta local: digite  $ip\NomeDoUsuario`nConta Microsoft (e-mail): digite  MicrosoftAccount\seu@email.com"
$cred = Get-Credential -Message $msg -UserName "$ip\"
if (-not $cred) { Write-Host 'Cancelado.' -ForegroundColor Yellow; Read-Host 'Enter para fechar'; exit 1 }

try {
    $nome = Invoke-Command -ComputerName $ip -Credential $cred -ScriptBlock { "$env:COMPUTERNAME ($((Get-WmiObject Win32_OperatingSystem).Caption))" } -ErrorAction Stop
    $dir = Join-Path $env:LOCALAPPDATA 'PC-Seguidor'
    New-Item -ItemType Directory -Force $dir | Out-Null
    $cred | Export-Clixml (Join-Path $dir 'notebook.cred')
    Write-Host ''
    Write-Host "CONECTADO com sucesso em: $nome" -ForegroundColor Green
    Write-Host 'Pode voltar para o Claude.' -ForegroundColor Green
} catch {
    Write-Host ''
    Write-Host 'NAO conectou. Mande esta mensagem para o Claude:' -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Read-Host "`nEnter para fechar"
