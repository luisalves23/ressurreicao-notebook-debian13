<#
  conectar-debian.ps1  (roda NESTA ESTACAO - use CONECTAR-DEBIAN.bat)
  Prepara o acesso do Claude ao notebook ja com Debian, via SSH com chave:
   1. Acha o notebook na rede pelo MAC do Wi-Fi (A0-D3-7A-XX-XX-XX) e porta 22
   2. Pergunta o nome do usuario criado na instalacao
   3. Envia a chave publica do Claude (o USUARIO digita a senha do Debian nesta janela)
   4. Libera sudo sem senha TEMPORARIO (/etc/sudoers.d/90-pc-seguidor-temp) para a
      manutencao remota - remover ao final do projeto
   5. Testa e grava o resultado em %LOCALAPPDATA%\PC-Seguidor\conexao-debian.log
  Nenhuma senha e gravada.
#>
$ErrorActionPreference = 'Continue'
$mac  = 'A0-D3-7A-XX-XX-XX'
$key  = Join-Path $env:USERPROFILE '.ssh\pc_seguidor_ed25519'
$dir  = Join-Path $env:LOCALAPPDATA 'PC-Seguidor'
New-Item -ItemType Directory -Force $dir | Out-Null
$log  = Join-Path $dir 'conexao-debian.log'
function Write-Log([string]$t) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $t" | Out-File $log -Append -Encoding UTF8; Write-Host $t }

# 1. Achar o notebook
Write-Host 'Procurando o notebook na rede...' -ForegroundColor Cyan
$net = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress -replace '\.\d+$',''
$p = 1..254 | ForEach-Object { (New-Object System.Net.NetworkInformation.Ping).SendPingAsync("$net.$_", 800) }
[System.Threading.Tasks.Task]::WaitAll($p)
$ip = (Get-NetNeighbor -AddressFamily IPv4 | Where-Object { $_.LinkLayerAddress -eq $mac -and $_.State -ne 'Unreachable' } | Select-Object -First 1).IPAddress
if (-not $ip) { Write-Log 'ERRO: notebook nao encontrado na rede (MAC do Wi-Fi nao apareceu).'; Read-Host 'Enter para fechar'; exit 1 }
Write-Log "Notebook encontrado em $ip"

# 2. Usuario
$user = Read-Host 'Digite o NOME DE USUARIO que voce criou na instalacao do Debian'
$user = $user.Trim()

# 3 + 4. Chave + sudo temporario (pede a senha do Debian nesta janela)
$pub = (Get-Content "$key.pub" -Raw).Trim()
$cmd = @"
mkdir -p ~/.ssh && chmod 700 ~/.ssh && grep -qF '$pub' ~/.ssh/authorized_keys 2>/dev/null || echo '$pub' >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys;
R="echo '$user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-pc-seguidor-temp && chmod 440 /etc/sudoers.d/90-pc-seguidor-temp && /usr/sbin/usermod -aG sudo $user";
if id -nG | grep -qw sudo; then echo '>>> Digite a SENHA DO SEU USUARIO:'; sudo sh -c "`$R"; else echo '>>> Digite a SENHA DO ROOT (administrador):'; su -c "`$R"; fi
"@
Write-Host ''
Write-Host 'Agora o Debian vai pedir SENHA (talvez duas vezes). Ao digitar, nada aparece na tela - e normal.' -ForegroundColor Yellow
# base64 evita problemas de aspas do PowerShell 5.1 ao passar argumentos para o ssh.exe
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($cmd -replace "`r","")))
ssh -t -o StrictHostKeyChecking=accept-new "$user@$ip" "echo $b64 | base64 -d > /tmp/pc-seguidor.sh && sh /tmp/pc-seguidor.sh; rm -f /tmp/pc-seguidor.sh"
Write-Log "Envio da chave/sudo: codigo $LASTEXITCODE"

# 5. Teste sem senha
$t = ssh -i $key -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$user@$ip" 'echo "$(hostname) | $(whoami) | sudo:$(sudo -n true 2>/dev/null && echo ok || echo FALHOU)"' 2>&1
if ($LASTEXITCODE -eq 0) {
    @{ ip = $ip; user = $user } | ConvertTo-Json | Out-File (Join-Path $dir 'debian.json') -Encoding UTF8
    Write-Log "CONECTADO: $t"
    Write-Host 'Tudo certo. Pode voltar para o Claude.' -ForegroundColor Green
} else {
    Write-Log "NAO conectou: $t"
    Write-Host 'O Claude ja consegue ler este erro. Pode voltar para ele.' -ForegroundColor Red
}
Read-Host "`nEnter para fechar"
