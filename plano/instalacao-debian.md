# Roteiro de instalação — Debian 13.8.0 netinst + Xfce

Roteiro de referência. Na prática, o Claude passa **um passo por vez**.

## Mídia
- ISO oficial: `debian-13.8.0-amd64-netinst.iso`, de cdimage.debian.org.
- SHA512 conferido contra o `SHA512SUMS` oficial (cópia em `iso/SHA512SUMS`).
- Gravada no pendrive **Ventoy** (rótulo `Ventoy`, 14,4 GB), copiada pela rede para a raiz do pendrive.

## Boot pelo pendrive
1. Notebook desligado, pendrive Ventoy conectado e **carregador ligado**.
2. Ligar e apertar a tecla do menu de boot. No Positivo costuma ser **F7**; se não for, testar **F12** ou **Esc**.
3. Escolher o pendrive (UEFI) → menu do Ventoy → `debian-13.8.0-amd64-netinst.iso` → boot normal.
4. **Secure Boot: ACONTECEU.** Ver a lição aprendida abaixo.

## ⚠️ Lição aprendida: Ventoy + Secure Boot
**O que houve (2026-11-22):** com o Secure Boot **ligado**, o boot pelo pendrive Ventoy parou numa
tela de **falha de verificação de segurança**. O Ventoy usa um carregador próprio que não é assinado
pela Microsoft, e a BIOS do Positivo o bloqueou.

**Como resolvemos:** desligamos o **Secure Boot** na BIOS. Depois disso, o menu do Ventoy abriu normalmente.

**Para as próximas pessoas:**
- **Antes de dar boot pelo Ventoy, confira o Secure Boot.** No Windows, rode `Confirm-SecureBootUEFI`
  no PowerShell como Administrador; se der `True`, está ligado.
- Escolha um destes caminhos:
  1. **Desligar o Secure Boot** na BIOS antes do boot. É o mais simples, e foi o que usamos.
  2. Registrar a chave do Ventoy no MokManager (*Enroll key from disk* → `ENROLL_THIS_KEY_IN_MOKMANAGER.cer`).
     Funciona, mas nem toda BIOS colabora.
  3. Gravar a ISO com **Rufus** (ou outra ferramenta que grava a ISO direto, em modo DD/ISO), em vez do Ventoy.
     A ISO oficial do Debian é assinada e dá boot **com o Secure Boot ligado**, sem esse problema.
- O Debian instalado funciona com o Secure Boot ligado. Depois da instalação dá para **religar** o Secure Boot.

## Respostas do instalador (*Install*, modo texto, que é o mais leve)
| Tela | Resposta |
|---|---|
| Idioma / país / teclado | Português do Brasil / Brasil / **Português Brasileiro (ABNT2)** |
| Rede | Wi‑Fi da casa (Intel AC 3160; o firmware vem incluso) |
| Hostname | `notebook-positivo` |
| Domínio | deixar em branco |
| Senha do root | **deixar em branco**: o usuário principal ganha `sudo` |
| Usuário | nome do seguidor + senha forte (o seguidor/usuário digita) |
| Fuso | definido pelo estado |
| Particionamento | **Assistido – usar o disco inteiro** → WD 500 GB → **todos os arquivos em uma partição** → confirmar. Apaga o Windows, a `C:` e a `D:` (vazias, conferido em 2026-11-22) |
| Espelho | Brasil → `deb.debian.org` |
| Concurso de popularidade | Não |
| Seleção de software | **desmarcar** "GNOME"; **marcar** "Ambiente de desktop Debian", **Xfce**, **servidor SSH** e utilitários padrão do sistema |
| GRUB | Em UEFI **não é perguntado**: o instalador coloca o `grub-efi` no HD sozinho |

## Primeiro acesso pela rede
- Nesta estação: clique duplo em `estacao/CONECTAR-DEBIAN.bat`, digite o nome do usuário e depois a senha do Debian.

## Encerramento do projeto (limpeza de acesso)
- Remover `/etc/sudoers.d/90-pc-seguidor-temp` e a linha `pc-seguidor-claude` de `~/.ssh/authorized_keys`.

## Depois de instalar (o Claude faz pela rede via SSH)
- zram (`zram-tools`), `vm.swappiness=10`, `noatime`
- cortar serviços desnecessários na inicialização
- Firefox ESR + uBlock Origin, LibreOffice
- `unattended-upgrades`
- medir o boot (`systemd-analyze`) e a RAM ocupada, para o antes e depois
- (opcional) religar o Secure Boot na BIOS e confirmar que o Debian continua dando boot
