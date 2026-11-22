# 06 — Resultados e desempenho

Comparativo consolidado: [`relatorios/comparativo.md`](../relatorios/comparativo.md).

## Boot

| Sistema | Tempo até o login |
|---|---|
| Windows 10 1803 | 131–410 s |
| Debian 13 recém-instalado | 100,6 s |
| Debian 13 otimizado | **44,7 s** (repetido após toda a customização: 45,0 s) |

## Abertura de aplicativos
Cronômetro automatizado ([`debian/demo-apps.sh`](../debian/demo-apps.sh)): o clique no dock dispara a contagem, e a janela visível (`xdotool search --sync --onlyvisible`) a encerra.
Condição: **1ª abertura após ligar, com o ffmpeg gravando a tela ao mesmo tempo** (o pior caso realista).

| App | Tempo |
|---|---|
| Arquivos (Thunar) | 1,9 s |
| Firefox ESR | **5,0 s** (era 15,3 s com o uBlock Origin) |
| Terminal | 2,1 s |
| Claude Code (janela) | 1,5 s (a interface leva ~20 s para desenhar) |
| LibreOffice Writer | 10,9 s |
| Editor (Mousepad) | 2,3 s |
| Configurações | 2,0 s |

## YouTube (vídeo tocando)

| Processo | CPU |
|---|---|
| Decodificação (RDD + VA‑API, `/dev/dri/renderD*` aberto) | **6–10%** |
| Firefox + aba | ~75% |
| CPU livre | 5–9% |

RAM: ~1,4 GB + ~670 MB comprimidos na zram. **Swap do HD sem uso.** O earlyoom não precisou agir.
Recomendação: 480p (o 720p funciona, mas no limite).

## Claude Code
Instalador oficial (`claude.ai/install.sh`, revisado: baixa de `downloads.claude.ai` com SHA256), versão 2.1.330 em `~/.local/bin`. `claude --help`: 0,54 s / 107 MB. O login fica por conta do dono da conta.

## Vídeos (em [`gravacoes/`](../gravacoes/), publicados com autorização do dono do notebook)
| Arquivo | Conteúdo |
|---|---|
| `01-antes-customizacao.mp4` | Debian padrão: roteiro fixo (área de trabalho, menu, Thunar maximizado, terminal) |
| `02-depois-customizacao.mp4` | Mesmo roteiro com o visual final |
| `03-apps-funcionando.mp4` (4 min 26 s) | Todos os apps pelo dock, YouTube, fastfetch, cmatrix, Claude Code, tempos |

Gravação: `ffmpeg -f x11grab -framerate 15 -c:v libx264 -preset ultrafast -crf 30`. Mouse com **trajetória humana**
(Bezier cúbica com pontos de controle aleatórios, easing, tremor de 1–2 px e passagem do alvo seguida de correção),
gerada em uma única chamada do `xdotool`.
