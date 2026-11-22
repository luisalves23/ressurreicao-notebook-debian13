# 07 — Guia para replicar em outro PC antigo

Público-alvo: quem tem um PC ou notebook de 2–4 GB de RAM e HD mecânico que "não roda mais nada".
Tempo estimado: 2–3 h (a maior parte é esperando a instalação).

> ⚠️ A instalação **apaga o disco inteiro**. Salve antes o que importa.

## 0. Diagnóstico (Windows)
1. Rode [`scripts/coletar-hardware.ps1`](../scripts/coletar-hardware.ps1) no PC (PowerShell → `powershell -ExecutionPolicy Bypass -File .\coletar-hardware.ps1`).
2. Confira no relatório:
   - **CPU 64 bits?** Se não, este guia não serve (o Debian 13 é só 64 bits).
   - **RAM** e **HDD/SSD**: com 2 GB e HD, este guia é o seu caso.
   - **Firmware UEFI/Legacy** e **Secure Boot**.
   - **SMART**: se prevê falha do disco, troque o disco antes.

## 1. Mídia
1. Baixe `debian-13.x.x-amd64-netinst.iso` de `https://www.debian.org/CD/netinst/` e **confira o SHA512** (`Get-FileHash -Algorithm SHA512`).
2. Grave com **Rufus** (mais simples, funciona com Secure Boot) ou copie para um pendrive **Ventoy**. Com Ventoy, **desligue o Secure Boot** antes.

## 2. Instalação
1. Boot pelo pendrive (tecla do menu de boot: F7/F12/Esc), escolha **Install** (modo texto).
2. Idioma/teclado → rede (Wi‑Fi) → usuário com senha (root em branco = o usuário ganha sudo).
3. Particionamento: **assistido, disco inteiro, tudo em uma partição**.
4. **Seleção de software:** desmarque **GNOME**; marque **Xfce**, **servidor SSH** (opcional) e **utilitários padrão**.

## 3. Otimização (no Debian instalado)
```bash
sudo bash debian/otimizar.sh          # zram, earlyoom, serviços, noatime, GRUB, initramfs, atualizações
sudo sh debian/ajustes-sessao.sh $USER # VA-API, Firefox leve, Xfce sem sombras, autostart enxuto
```
Antes, revise os scripts. O `ajustes-sessao.sh` assume GPU Intel antiga (driver `i965`); em AMD/NVIDIA, remova o passo 1.
Meça antes e depois com `sudo sh debian/medir.sh`.

## 4. Visual estilo Mac (opcional)
```bash
# ícones WhiteSur (GitHub, revise o install.sh antes de rodar)
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme && ./WhiteSur-icon-theme/install.sh
sudo apt install arc-theme
bash debian/dock-plank.sh                                   # dock + barra superior
sudo bash debian/tela-bloqueio/aplicar.sh $USER debian/tela-bloqueio   # tela de bloqueio (reinicie depois)
```
Os scripts usam a foto `/usr/share/backgrounds/pc-seguidor/vernazza.jpg`. Troque pela sua.

## 5. Conferência final
- [ ] `systemd-analyze` < 60 s
- [ ] `swapon --show` lista `/dev/zram0` com prioridade 100
- [ ] `systemctl is-active earlyoom` → active
- [ ] `vainfo` mostra perfis H.264 (se a GPU for Intel)
- [ ] Firefox abre em < 10 s; YouTube toca em 480p
- [ ] Carregador conectado mostra "charging" de forma estável (`upower -i $(upower -e | grep BAT)`)

## 6. Expectativa realista
Um Celeron de 2 núcleos continua sendo um Celeron. O que muda é que o sistema para de brigar com o hardware:
navegação, documentos, vídeo em 480p e estudo passam a ser viáveis. Para mais, o upgrade de melhor
custo‑benefício é **SSD** (primeiro) e depois **RAM**.
