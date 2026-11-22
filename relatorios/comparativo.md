# Comparativo — Positivo S14BW01 (Celeron N3010, 2 GB RAM, HD 5400 rpm)

Mesmo hardware nos três momentos, sem trocar peças.

| | Windows 10 1803 (original) | Debian 13 recém-instalado | **Debian 13 otimizado** |
|---|---|---|---|
| **Tempo para ligar** (até a tela de login) | **131 s a 410 s** (2 a 7 min) | 1 min 40 s (100,6 s) | **44,7 s** |
| Firmware + carregador | — | 2,7 + 15,3 s | 2,7 + **8,8 s** |
| Kernel | — | 11,0 s | 10,3 s |
| Serviços (userspace) | — | 71,7 s | **23,0 s** |
| RAM usada parado | 1,7 GB (só 0,2 GB livres) | 408 MB | **398 MB** |
| Memória de troca | HD | Só HD (1,9 GB) | **zram 1,1 GB na RAM** + HD de reserva |
| CPU parado | 90% | — | — |

Fontes: `inventario-DESKTOP-BBF5M1P-20261122-1244.txt` (Windows), `debian-antes-otimizacao-*.txt`, `debian-depois-otimizacao-*.txt`.

## O que fez diferença no boot (sendo honesto)
- **AppArmor: 44,6 s → 1,4 s.** Isso é do **primeiro boot**, quando o AppArmor monta o cache dos perfis.
  Não foi otimização nossa: aconteceria em qualquer segundo boot.
- **Espera pela rede: −7 s.** Desligado o `NetworkManager-wait-online`, que segurava o boot até o Wi‑Fi conectar.
- **Menu do GRUB: −5 s.** O tempo de espera caiu de 5 s para 1 s.
- **Serviços que saíram do boot:** ModemManager, cups-browsed, avahi e e2scrub_reap. Somados, eram mais 5–7 s no HD.
- O ganho real das otimizações no boot é de uns 15–20 s. O resto veio do cache do AppArmor.

## O que faz diferença no uso (não aparece no boot)
- **zram**: quando a RAM enche, o Linux comprime na própria RAM em vez de usar o HD.
  No Windows, era exatamente isso que travava os apps.
- **earlyoom**: se um site estourar a memória, ele fecha a aba/navegador em vez de o notebook congelar.
- **noatime**: o HD deixa de gravar a data de acesso cada vez que um arquivo é lido.
- **uBlock Origin** no Firefox: menos anúncio, menos RAM e CPU por página.
