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

### Acesso SSH ao Debian
- `CONECTAR-DEBIAN.bat` rodado pelo usuário: chave enviada e sudo temporário criado. Host `notebook-seguidor`, usuário `usuario`, Debian 13.8, kernel 6.12.117.
- O teste final do conector acusou erro falso: o PowerShell 5.1 tirou as aspas e o shell leu os `|` como pipes.
  O acesso foi confirmado à mão (`SUDO_OK`) e o teste foi corrigido.

### Medição inicial → otimização → medição final
- `debian/medir.sh` (só leitura) antes: boot **1 min 40 s**, 408 MB usados, swap só no HD.
  Maiores atrasos: apparmor 44,6 s (cache do 1º boot) e NetworkManager-wait-online 7 s.
- `debian/otimizar.sh` aplicado (log em `relatorios/debian-otimizacao-log-*.txt`), **10 passos, EXIT=0**:
  zram (zstd, 60%, prio 100), swappiness 150 / page-cluster 0, earlyoom, serviços desligados
  (NM-wait-online, ModemManager, cups-browsed, avahi, e2scrub_reap; cups sob demanda), `noatime`
  (backup `/etc/fstab.antes-pc-seguidor`, troca testada antes numa cópia), GRUB 1 s, initramfs `MODULES=dep`,
  atualizações de segurança automáticas, uBlock Origin.
- Revisão antes de rodar pegou 3 bugs no próprio script: o `fstab` do Debian não tem `relatime` escrito,
  o `cp -n` pode falhar e as aspas no `EARLYOOM_ARGS` não funcionam no systemd.
- Reiniciado remotamente: SSH voltou em 58 s. **Boot final: 44,7 s** (userspace 71,7 → 23,0 s; carregador 15,3 → 8,8 s).
- Comparativo Windows × Debian em `relatorios/comparativo.md`.

### Sessão gráfica e travamento
- Usuário fez login no Xfce. RAM com a área de trabalho: **583 MB usados, 1,24 GB disponíveis**.
  Compositor ligado. Drivers VA‑API (i965/iHD) já instalados.
- Logo depois, **o notebook sumiu da rede** (sem ping, sem SSH) e a tela apagou. Não acordou com tecla.
  O usuário teve de **forçar o desligamento** (botão por ~20 s), ou seja, **travou** e não estava suspenso.
- Suspeita: travamento conhecido dos Celeron Braswell/Cherry Trail no Linux quando ociosos (estados de
  economia C-state profundos). A conferir no log do boot anterior (`journalctl -b -1`).
- Ao religar: **"Secure Boot Violation – Invalid signature detected"**. O Secure Boot voltou a valer
  (a BIOS pode ter voltado ao padrão no desligamento forçado, ou o pendrive Ventoy ainda estava plugado).
  Minha afirmação de que "o Debian dá boot com o Secure Boot ligado" **não vale para esta BIOS de 2016**,
  que provavelmente não traz o certificado de terceiros da Microsoft usado pelo shim do Debian.
  Solução: desligar o Secure Boot na BIOS de novo e tirar o pendrive.

### ✅ Causa real do "travamento": BATERIA ACABOU (corrige as suspeitas acima)
- Depois de desligar o Secure Boot, o Debian ligou. `uptime` de 21 min e o mesmo `boot_id` mostraram que
  **ele não reiniciou: voltou da hibernação**.
- Log: às **14:55:46**, `systemd-logind: The system will hybrid sleep now!`.
- Histórico do UPower: **bateria descarregando** de 6% (14:49) até 2% (14:55:25). Às 14:50:13 o carregador
  apareceu como "charging" por um instante e sumiu: **plugue do carregador possivelmente frouxo**.
- A UPower do Debian tem `CriticalPowerAction=HybridSleep` com 2%. A suspensão híbrida gravou a memória
  no HD e dormiu. A bateria zerou de vez, e no religamento o sistema voltou da imagem no HD.
- **Secure Boot religado:** a explicação mais provável é que a BIOS voltou ao padrão de fábrica com a
  bateria totalmente zerada. Não confirmado.
- **Descartado:** travamento por C-states do Braswell (minha primeira suspeita estava errada).
- Bateria agora: 9%, carregando a 11,3 W, saúde 96,7%.
- **Correção:** `CriticalPowerAction=Hibernate` (backup `/etc/UPower/UPower.conf.antes-pc-seguidor`).
  Com 2%, o notebook grava a sessão e **desliga de verdade**, sem drenar a bateria até zerar.

### Ajustes de sessão (`debian/ajustes-sessao.sh`, log em `relatorios/debian-ajustes-sessao-log-*.txt`)
- Teste de vídeo (`vainfo`): o driver **i965** decodifica **H.264, VP8 e HEVC** pela placa; **não faz VP9/AV1**.
  O iHD falha neste Celeron. Fixado `LIBVA_DRIVER_NAME=i965`.
- Firefox ESR 153 (`/etc/firefox-esr/firefox-esr.js`, bloco `pc-seguidor`, 12 preferências): 2 processos de conteúdo,
  libera abas com pouca RAM, VA-API forçado, **VP9 e AV1 desligados para o YouTube mandar H.264**
  (decodificado pela placa), sessão salva a cada 60 s, sem prefetch, sem Pocket nem patrocinados.
- Xfce: sombras desligadas. O compositor continua ligado para o vídeo não rasgar.
- Fora da inicialização: print-applet (39 MB), xfce4-notes e xiccd.

### Teste do YouTube
- Na 1ª abertura do Firefox, o uBlock Origin compilou as listas: 635 MB e 49% de CPU, a RAM lotou
  e a zram segurou (938 MB → 246 MB). Passou sozinho em ~1 min, e o **earlyoom não fechou nada**.
- Vídeo tocando: a decodificação pela placa **confirmada** (o processo RDD tem `/dev/dri/renderD*` aberto) com 6–10% de CPU.
  Firefox + aba somam ~75%. Sobra pouca CPU: recomendado 480p.
- RAM: 1,4 GB usados + ~670 MB comprimidos na zram; **swap do HD não foi usada**.
- Detalhes em `relatorios/comparativo.md`.

- Retorno do usuário: o vídeo rodou em qualidade "ok" e travou muito pouco. Apps abrem rápido.
  No Windows, o terminal levava 3 minutos para abrir e o navegador nem abria.

### Claude Code (pedido do seguidor)
- Instalados `curl`, `git` e `ripgrep`, que faltavam.
- Instalador oficial (`https://claude.ai/install.sh`) **baixado e revisado antes de rodar**: baixa de
  `downloads.claude.ai` e confere SHA256. Rodado como `usuario`, sem sudo, como o próprio instalador exige.
- Instalado **Claude Code 2.1.330** em `~/.local/bin/claude`. Log em `relatorios/claude-code-instalacao-log-*.txt`.
- `~/.local/bin` não entrava no PATH da sessão atual (a pasta não existia no login). Fixado no `~/.bashrc`
  com um bloco `pc-seguidor`. Um terminal novo acha o `claude`.
- `claude --help`: 0,54 s e 107 MB de RAM. **Falta o login** com a conta do seguidor (`claude`, depois `/login`),
  que é dele: eu não faço.

### Dock estilo Mac (avaliação)
- Ver `plano/dock-estilo-mac.md`. Dá para fazer: zoom, esconder e translucidez com o Plank (está no Debian 13).
  Blur real só como teste (picom). O efeito de lente Liquid Glass não é viável.

### Customização visual estilo Mac
- **Gravação ANTES** (`gravacoes/01-antes-customizacao.mp4`) feita antes de mexer em qualquer coisa, com ffmpeg + xdotool
  num roteiro fixo (`debian/demo-gravacao.sh`). O mouse se move "de mão" (curvas de Bezier, aceleração, tremor),
  a pedido do usuário. Bugs resolvidos no caminho: `ffmpeg` lendo o script pela entrada (`-nostdin`), pasta "Vídeos"
  com acento mal codificado e `awk` em pt_BR escrevendo "0,012" (`LC_ALL=C`).
- **Papel de parede:** primeiro um original gerado ("Entardecer", SVG, que fica no repo); depois trocado pela foto
  escolhida pelo usuário (Vernazza, Unsplash/Anders Jildén), recortada para 1366×768.
- **Ícones:** a instalação do WhiteSur (GitHub) foi barrada pela regra de segurança da sessão, então entrou o
  elementary-xfce (repo Debian). Com a **autorização explícita do usuário**, o WhiteSur foi instalado (instalador
  revisado antes, rodado sem root). Janelas: tema Arc.
- **Dock (Plank):** a v1 ficou grande, espaçada e com zoom exagerado (crítica do usuário). Na v3, seguindo a imagem de
  referência: paddings em décimos do ícone (1,2/1,4/1,4/2), ícone 42, zoom 128%, vidro com borda sutil,
  some com janela maximizada e volta com o mouse na borda (testado). Ícone do Claude Code com o **símbolo oficial**
  (Wikimedia Commons) num squircle claro.
- **Barra de cima:** escura translúcida, só com menu, bandeja, relógio e ações. O painel de baixo foi removido.
- **Erros meus corrigidos:** `xfconf-query -rR /panels` apagou o painel de cima inteiro (restaurado do backup); a cópia
  do `thunar.desktop` fazia o Plank mostrar um ícone extra; o script recriava os atalhos com o Plank aberto e ele reordenava tudo.
- **Gravação DEPOIS:** `gravacoes/02-depois-customizacao.mp4`.
- RAM com a área de trabalho: 556 MB antes → ~690 MB depois (Plank ~40 MB; o resto é cache de ícones e tema).

### Tela de bloqueio estilo Mac (`debian/tela-bloqueio/`)
- Quem bloqueia é o light-locker, que mostra o LightDM GTK greeter 2.0.9, a mesma tela do login.
- Aplicado: fundo = Vernazza **desfocada** (gerada uma vez com o ffmpeg `gblur`), avatar próprio (degradê do pôr do sol
  + inicial, registrado no AccountsService), tema Arc-Dark, CSS de vidro (`/var/lib/lightdm/.config/gtk-3.0/gtk.css`),
  data e hora em pt-BR no topo, botão de energia. `greeter-hide-users=false` para mostrar nome e avatar
  (**só vale depois de reiniciar**: o LightDM lê isso ao iniciar).
- **Não dá:** os dois estados do macOS (foto nítida + relógio grande → clique → desfoque) e o player de música.
  O greeter GTK tem um estado só. Os greeters em HTML rodam um navegador inteiro a cada bloqueio: pesado e lento demais aqui.
- **Layout:** avatar e campos ficam lado a lado (fixo no greeter, o CSS não muda).
- Teste remoto: bloqueio com `light-locker-command -l`, foto do display `:1`. Após o `loginctl unlock-session`, o
  light-locker não voltou sozinho para o tty7, então voltei com `chvt 7`. No uso normal, a senha digitada faz essa volta.

### Pendências
- Reiniciar para valer o nome + avatar na tela de login/bloqueio e conferir se o Plank abre sozinho no login.
- Opcional: religar o Secure Boot? **Não recomendado**: esta BIOS de 2016 barrou o boot do Debian com ele ligado.
- Conferir o plugue do carregador (possível mau contato).
- Opcional: religar o Secure Boot.
- Fim do projeto: remover o sudo temporário e a chave SSH.
