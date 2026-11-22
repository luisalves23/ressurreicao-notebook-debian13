# 02 — Acesso remoto

O projeto foi feito quase todo **de outra máquina na mesma rede** (a "estação"). O dono do notebook só
fez o que exige a mão no equipamento: ligar, apertar teclas, digitar senhas.

## Fase Windows — WinRM (PowerShell Remoting)

**Por que WinRM:** já vem no Windows 7/10, não precisa baixar nada no PC lento e é reversível.

| Passo | Onde | O quê |
|---|---|---|
| 1 | Estação | Varredura da rede: ping assíncrono em /24, tabela ARP e portas 22/135/139/445/3389/5985. O notebook aparece como um MAC de fabricante Intel sem portas abertas (firewall em rede "Pública") |
| 2 | Notebook (pendrive, Administrador) | [`scripts/liberar-acesso-remoto.ps1`](../scripts/liberar-acesso-remoto.ps1): rede → Privada, `Enable-PSRemoting`, firewall só para `localsubnet`, `LocalAccountTokenFilterPolicy=1`. Tem `-Desfazer` |
| 3 | Estação (Administrador) | [`estacao/CONECTAR-NOTEBOOK.bat`](../estacao/CONECTAR-NOTEBOOK.bat): liga o serviço WinRM local, grava o `TrustedHosts`, pede a credencial numa janela do Windows e a guarda **criptografada com DPAPI fora do repositório** |
| 4 | Estação | `Invoke-Command -FilePath scripts/coletar-hardware.ps1` → inventário em 59 s |

**Armadilhas encontradas**
- *Falha na 1ª conexão:* o serviço **WinRM da estação** estava parado, e sem ele o `Set-Item WSMan:\...\TrustedHosts` não grava. Correção: `Start-Service WinRM` antes.
- *Aviso falso de "usuário sem senha":* `Win32_UserAccount.PasswordRequired` não indica se a senha existe.
- *Cópia de arquivo grande pela sessão:* conferir o hash **durante** a cópia travou o arquivo e corrompeu a transferência. Só conferir depois que a cópia terminar.

## Fase Debian — SSH com chave

| Passo | O quê |
|---|---|
| Chave | Par **ed25519 exclusivo do projeto** gerado na estação (`~/.ssh/pc_seguidor_ed25519`, nunca versionado) |
| Envio | [`estacao/CONECTAR-DEBIAN.bat`](../estacao/CONECTAR-DEBIAN.bat): acha o notebook pelo MAC, envia a chave pública (o dono digita a senha **na janela**), cria `sudo` **temporário** sem senha em `/etc/sudoers.d/90-pc-seguidor-temp` e testa |
| Uso | Todos os scripts `debian/*.sh` são enviados em **base64** e executados via `ssh ... "echo <b64> \| base64 -d \| bash"` |
| Limpeza (fim do projeto) | Remover o `sudoers.d` temporário e a linha `pc-seguidor-claude` do `authorized_keys` |

**Armadilhas encontradas**
- *PowerShell 5.1 remove aspas duplas* nos argumentos de executáveis nativos (`ssh.exe`), e o shell remoto passa a interpretar `|` e `$()`. Solução: mandar o script em base64, sem aspas internas.
- *Codificação:* `Get-Content` sem `-Encoding UTF8` leu um script como ANSI, e a pasta "Vídeos" foi criada como `VÃ­deos`. Solução: ler sempre como UTF‑8 e evitar acentos em código (`xdg-user-dir VIDEOS`).
- *Locale pt_BR:* o `awk` escrevia `0,012`, e o `xdotool sleep` lia isso como zero. Solução: `LC_ALL=C`.
- *ffmpeg em script lido de pipe:* sem `-nostdin`, o ffmpeg consome o resto do script como comandos de teclado.
- *Aplicativos gráficos iniciados por SSH* precisam de `DISPLAY=:0`, `DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus` e, no Plank, `XDG_SESSION_TYPE=x11`.

## Boot remoto pelo pendrive (sem tecla de BIOS)
No Windows, ainda pela rede:
```
bcdedit /enum firmware                                   # acha "UEFI:Removable Device"
bcdedit /set {fwbootmgr} bootsequence {<guid-do-removable>}   # vale só para o próximo boot
shutdown /r /t 5
```
