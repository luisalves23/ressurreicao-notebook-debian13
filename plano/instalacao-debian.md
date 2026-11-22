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
4. **Secure Boot está ligado.** Na primeira vez, o Ventoy pode mostrar uma tela azul "Verification failed".
   Nesse caso, há dois caminhos:
   - registrar a chave do Ventoy: *Enroll key from disk* → `ENROLL_THIS_KEY_IN_MOKMANAGER.cer`;
   - ou desligar o Secure Boot na BIOS durante a instalação.

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
| GRUB | Sim, no disco principal |

## Depois de instalar (o Claude faz pela rede via SSH)
- zram (`zram-tools`), `vm.swappiness=10`, `noatime`
- cortar serviços desnecessários na inicialização
- Firefox ESR + uBlock Origin, LibreOffice
- `unattended-upgrades`
- medir o boot (`systemd-analyze`) e a RAM ocupada, para o antes e depois
