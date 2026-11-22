# 03 — Instalação e otimização

## Escolha do sistema (resumo — detalhes em [plano/escolha-do-sistema.md](../plano/escolha-do-sistema.md))

| | **Debian 13 netinst + Xfce** | Linux Mint 22.3 Xfce | MX Linux 25 Xfce |
|---|---|---|---|
| RAM parado (aprox.) | **~450–550 MB** | ~800 MB–1 GB | ~600–700 MB |
| Suporte | **até 30/06/2030** (LTS) | até 04/2029 | segue o Debian 13 |
| O que vem instalado | só o escolhido | muitos extras | muitas ferramentas próprias |

## Mídia
- `debian-13.8.0-amd64-netinst.iso` (758 MB) de `cdimage.debian.org`. **SHA512 conferido** na estação e de novo **no próprio pendrive** ([iso/SHA512SUMS](../iso/SHA512SUMS)).
- Pendrive com **Ventoy**: a ISO foi copiada pela rede (WinRM `Copy-Item -ToSession`, 610 s via Wi‑Fi).
- ⚠️ **O Secure Boot ligado bloqueou o Ventoy** ("Verification failed"). Ver o [capítulo 04](04-incidentes-e-licoes.md).

## Instalação (instalador em modo texto)
Roteiro completo em [plano/instalacao-debian.md](../plano/instalacao-debian.md). Pontos-chave:
- pt_BR, teclado ABNT2, Wi‑Fi `wlp3s0` (o firmware do Intel 3160 vem no instalador);
- particionamento assistido com o disco inteiro (Windows e dados descartados: as pastas estavam vazias);
- **Seleção de software:** desmarcar GNOME; marcar Xfce, **Servidor SSH** e utilitários padrão;
- em UEFI o instalador **não pergunta** sobre o GRUB: ele instala o `grub-efi` sozinho.

## Otimização — [`debian/otimizar.sh`](../debian/otimizar.sh) (idempotente, log em `relatorios/`)

| # | Ajuste | Por quê |
|---|---|---|
| 1 | `zram-tools`: zstd, 60% da RAM, prioridade 100 | Quando a RAM enche, comprime na própria RAM (taxa medida: 3,8×) em vez de paginar no HD |
| 2 | `vm.swappiness=150`, `vm.page-cluster=0`, `vfs_cache_pressure=50` | Com zram, trocar é barato; sem leitura antecipada inútil |
| 3 | `earlyoom` (`-m 5 -s 10`, prefere fechar o navegador, nunca Xorg/Xfce/sshd) | Evita congelar o sistema quando um site estoura a memória |
| 4 | Desligados: `NetworkManager-wait-online`, `ModemManager`, `cups-browsed`, `avahi`, `e2scrub_reap`; cups via socket | −7 s de espera pela rede e serviços inúteis neste hardware |
| 5 | `noatime` na raiz (backup do fstab, validado com `findmnt --verify`, testado antes numa cópia) | Menos escritas no HD |
| 6 | `GRUB_TIMEOUT=1` | −4 s |
| 7 | `MODULES=dep` no initramfs | initrd menor, menos leitura do HD |
| 8 | `unattended-upgrades` | Segurança sem intervenção |
| 9 | UPower `CriticalPowerAction=Hibernate` | Com 2% de bateria, grava a sessão e desliga, sem drenar até zerar (ver o incidente da bateria) |

### Ajustes de sessão — [`debian/ajustes-sessao.sh`](../debian/ajustes-sessao.sh)
- `LIBVA_DRIVER_NAME=i965`: o `iHD` falha neste Celeron; o i965 decodifica H.264/VP8/HEVC.
- Firefox ESR (`/etc/firefox-esr/firefox-esr.js`): `dom.ipc.processCount=2`, `unloadOnLowMemory`, VA‑API forçado, **VP9 e AV1 desligados** (o YouTube passa a mandar H.264, que a placa decodifica), sessão salva a cada 60 s, sem prefetch, sem telemetria e sem a pergunta ao sair.
- Xfce: sem sombras. O compositor fica ligado, para o vídeo não rasgar.
- Fora do autostart: print‑applet, xfce4‑notes, xiccd.
- **uBlock Origin removido**: recompilava os filtros a cada abertura do Firefox (~570 MB / 50% de CPU). Ver o capítulo 04.

## Medição — [`debian/medir.sh`](../debian/medir.sh)

| | Antes da otimização | Depois |
|---|---|---|
| Boot total | 1 min 40,6 s | **44,7 s** |
| Carregador (GRUB) | 15,3 s | 8,8 s |
| Kernel | 11,0 s | 10,3 s |
| Userspace | 71,7 s | **23,0 s** |
| RAM na tela de login | 408 MB | 398 MB |

**Atribuição honesta:** o maior item do "antes" era o `apparmor.service` com 44,6 s, que é a montagem do cache de perfis **no primeiro boot**. No segundo boot ele levou 1,4 s, com ou sem otimização. O ganho real dos ajustes no boot foi de ~15–20 s. O ganho maior deles aparece **no uso** (zram + earlyoom).
