# Diário técnico

Registro em ordem cronológica de tudo o que foi feito. Cada entrada corresponde
a um ou mais commits no Git.

## 2026-11-22

### Início do projeto
- Criado o repositório para versionar todo o trabalho.
- Rede local deste PC (estação de trabalho): Wi‑Fi `192.168.100.149`, gateway `192.168.100.1`.

### Primeira varredura de rede
- Varridos todos os endereços `192.168.100.1–254` (ping + ARP + portas 22, 135, 139, 445, 3389, 5985).
- **Nenhum PC Windows encontrado além desta estação.** Os aparelhos ativos
  (.1, .7, .9, .22, .24, .26, .27, .29, .32, .45, .70, .81, .155) não têm
  portas de Windows abertas — são roteador, celulares, TVs e afins.
- Motivo: o PC do seguidor **ainda não foi conectado ao Wi‑Fi**.
- Próximo passo: conectar o PC na rede e rodar `scripts/liberar-acesso-remoto.ps1` nele.

### Ferramentas preparadas
- `scripts/coletar-hardware.ps1`: inventário só-leitura, testado nesta estação (estação de trabalho do autor) — rodou sem erros.
- `scripts/liberar-acesso-remoto.ps1`: liga WinRM no PC do seguidor, com firewall restrito à rede local e opção `-Desfazer`.
- Escolhido WinRM (PowerShell Remoting) em vez de SSH/AnyDesk: já vem no Windows 7/10, não precisa baixar nada no PC velho e é reversível.

### Segunda varredura — notebook conectado ao Wi‑Fi
- O equipamento é um **notebook**.
- Dois aparelhos novos na rede:
  - `192.168.100.158` — MAC `A0-D3-7A-XX-XX-XX` (MAC de fábrica, de placa Wi‑Fi). **Provável notebook.**
  - `192.168.100.156` — MAC `8A-E5-56-AD-B2-B3` (MAC aleatório, típico de celular). Descartado.
- O `.158` não responde ping e não tem nenhuma porta aberta: é o comportamento
  do firewall do Windows em rede "Pública". **Não dá para acessar sem liberar
  algo no próprio notebook.**
- Próximo passo: confirmar o IP no notebook com `ipconfig`.
- **Confirmado com `ipconfig` no notebook: o IP dele é `192.168.100.158`.**
- Próximo passo: levar `scripts/liberar-acesso-remoto.ps1` ao notebook por pendrive.

### Acesso remoto liberado no notebook (Windows 10)
- Pasta `scripts` copiada por pendrive (letra `E:`) e `liberar-acesso-remoto.ps1` executado como Administrador.
- Resultado: "ACESSO LIBERADO". O script avisou "usuário sem senha", mas o usuário
  já tinha colocado senha antes — o aviso usa o campo `PasswordRequired`, que não
  diz se a senha existe. **Falso alarme; ajustar o aviso depois.**
- Teste daqui: ping OK, **porta 5985 (WinRM) aberta**, `Test-WSMan` respondeu. 135/445 seguem fechadas (esperado).
- Criado `estacao/CONECTAR-NOTEBOOK.bat` (clique duplo nesta estação): confia no IP,
  pede usuário/senha numa janela do Windows, guarda a credencial criptografada
  fora do Git (`%LOCALAPPDATA%\PC-Seguidor\notebook.cred`) e testa a conexão.
- Mudança de método de trabalho: comandos para o usuário passam a vir **prontos em
  arquivo de clique duplo**, nada para digitar.

### 1ª tentativa de conexão — falhou
- Usuário usado: `Usuario` (nome da conta local do notebook).
- Causa encontrada **nesta estação**: o serviço WinRM estava **parado** (Manual/Stopped),
  então o `TrustedHosts` não foi gravado (continua vazio) e a conexão por IP é recusada.
- Correção em `estacao/conectar-notebook.ps1`: liga o WinRM antes de gravar o
  TrustedHosts, para se der erro e grava tudo em `%LOCALAPPDATA%\PC-Seguidor\conexao.log`
  (sem senha) para diagnóstico sem precisar de foto.

### 2ª tentativa — CONECTADO
- Conectado como `192.168.100.158\Usuario` em **DESKTOP-BBF5M1P** (Windows 10 Home Single Language).
  O login levou cerca de 90 s, reflexo da lentidão do notebook.

### Inventário coletado pela rede
- `coletar-hardware.ps1` rodou remotamente em 59 s, sem fechar nada: o OBS Studio seguiu gravando a tela do notebook.
- Relatório em `relatorios/inventario-DESKTOP-BBF5M1P-20261122-1244.txt`.
- Resumo: Positivo S14BW01, Celeron N3010 (2 núcleos, 1,04 GHz), **2 GB DDR3** (2 slots, máx. 8 GB),
  **HD WD 500 GB 5400 rpm** (SMART ok), Windows 10 **1803** (2018), bateria 97%, boot de 131 a 410 s.
- Gargalos: HD mecânico + 2 GB RAM. Plano em `plano/diagnostico-e-plano.md`.

### Decisão: sem troca de peças → Debian 13 + Xfce
- Decidido que **não haverá SSD nem RAM extra** por enquanto.
- Conferido pela rede o hardware que importa para o Linux: áudio Realtek ALC269, Wi‑Fi Intel 3160,
  touchpad Synaptics, webcam UVC. Tudo com suporte bom. UEFI 64 bits com Secure Boot ligado, disco GPT.
  Pastas do usuário e `D:` vazias.
- Comparados Debian 13, Mint 22.3 e MX 25. **Escolhido Debian 13 (netinst) + Xfce**: menos RAM
  ocupada e suporte até 2030. Detalhes em `plano/escolha-do-sistema.md`.

### Mídia de instalação
- Plano aprovado: Debian 13 netinst + Xfce.
- Versão atual em cdimage.debian.org: **13.8.0**. Baixada `debian-13.8.0-amd64-netinst.iso` (758 MB) para `iso/`
  (fora do Git pelo `.gitignore`; o `SHA512SUMS` oficial fica versionado).
- **SHA512 confere** com o oficial: `825d85a0…0558eaadb`.
- Sem Rufus: o pendrive do usuário já tem **Ventoy**. Ele estava no notebook como `E:` (rótulo `Ventoy`, 3,1 GB livres).
  A ISO foi copiada **pela rede** (WinRM) para a raiz do pendrive.
- Roteiro de instalação em `plano/instalacao-debian.md`.
- **1ª cópia falhou**: uma conferência de hash feita no meio da cópia travou o arquivo
  (o Windows mostra o arquivo antes de terminar; só havia 424 de 795 MB). Lição: só conferir depois que a cópia terminar.
- **2ª cópia OK** (610 s pelo Wi‑Fi): 794.820.608 bytes, **SHA512 confere no próprio pendrive**.

### Boot pelo pendrive sem apertar tecla
- `bcdedit /enum firmware` no notebook mostra a entrada `UEFI:Removable Device` `{d271875f-49bd-11ef-84d0-806e6f6e6963}`.
- Plano: `bcdedit /set {fwbootmgr} bootsequence {d271875f-…}` (vale **só para o próximo boot**) e reiniciar
  remotamente. O notebook cai direto no Ventoy.
- Antes disso, parar a gravação do OBS no notebook, para não corromper o vídeo.
- Usuário parou o OBS. Executado pela rede: `bootsequence` = `UEFI:Removable Device` (confirmado no `bcdedit`)
  e `shutdown /r /t 5`. **Último comando executado no Windows 10 deste notebook.**
- O boot único pelo USB **funcionou**: o notebook foi direto para o pendrive.

### ⚠️ Problema: Secure Boot bloqueou o Ventoy
- Com o Secure Boot **ligado** (já detectado no levantamento: `Confirm-SecureBootUEFI = True`),
  o Ventoy parou em **erro de falha de verificação de segurança**.
- **Solução aplicada pelo usuário:** desligar o Secure Boot na BIOS. Em seguida, **o menu do Ventoy abriu**.
- Falha nossa: o Secure Boot ligado estava anotado como risco no roteiro, mas **não foi tratado antes do boot**.
  Com Rufus (gravação direta da ISO assinada do Debian) isso não teria acontecido.
- Lição registrada em `plano/instalacao-debian.md` ("Lição aprendida: Ventoy + Secure Boot").
- Pós-instalação: avaliar religar o Secure Boot (o Debian instalado é compatível).

### Instalador do Debian (modo texto)
- Idioma: Português do Brasil. Teclado: Português Brasileiro.
- Rede: o instalador achou as duas placas, `ens1f1` (Realtek, cabo) e `wlp3s0` (Intel Wireless 3160).
  O firmware do Wi‑Fi carregou sozinho. Escolhida a `wlp3s0` (Wi‑Fi).
- Usuário adiantou as telas seguintes para o vídeo não ficar longo: Wi‑Fi da rede local conectado,
  usuário criado, **particionamento assistido com o disco inteiro** (só o HD interno WD 500 GB, apagando
  Windows, `C:` e `D:`), esquema padrão. Instalação do sistema básico em andamento.
- Alerta enviado sobre a tela que ainda vem: **seleção de software** (trocar GNOME por Xfce e marcar o servidor SSH).

### Acesso ao Debian preparado (enquanto instala)
- Chave SSH própria do projeto gerada nesta estação: `~/.ssh/pc_seguidor_ed25519` (ed25519, sem senha,
  **fora do Git**; só a pública vai para o notebook).
- `estacao/CONECTAR-DEBIAN.bat` + `conectar-debian.ps1` (clique duplo):
  - acha o notebook pelo MAC do Wi‑Fi;
  - pergunta o nome do usuário;
  - envia a chave pública, e o **usuário digita a senha do Debian na própria janela**;
  - cria um `sudo` sem senha **temporário** em `/etc/sudoers.d/90-pc-seguidor-temp`, para a manutenção remota;
  - testa e grava o log em `%LOCALAPPDATA%\PC-Seguidor\conexao-debian.log`.
- O comando remoto vai em base64, porque o PowerShell 5.1 quebra aspas nos argumentos do `ssh.exe`.
- **Pendência de fim de projeto:** remover `/etc/sudoers.d/90-pc-seguidor-temp` e a chave do `authorized_keys`.

### Seleção de software (tasksel)
- Confirmado pelo usuário: **GNOME desmarcado**; marcados **Ambiente de desktop Debian + Xfce + Servidor SSH +
  Utilitários de sistema padrão**; servidor web e outras interfaces desmarcados.
- Instalação dos pacotes em andamento.

### Instalação concluída
- O instalador **não perguntou sobre o GRUB**: em máquina UEFI, o Debian instala o `grub-efi` sozinho na
  partição EFI do HD. O roteiro foi corrigido.
- Primeiro boot direto no Debian, com a tela de login do Xfce (LightDM).
- Daqui: notebook encontrado pelo MAC no **mesmo IP `192.168.100.158`**, **porta 22 (SSH) aberta**.
