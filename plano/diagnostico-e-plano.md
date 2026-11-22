# Diagnóstico e plano — Notebook Positivo S14BW01

Inventário completo: `relatorios/inventario-DESKTOP-BBF5M1P-20261122-1244.txt` (coletado pela rede em 2026-11-22).

## O que é a máquina

| Peça | O que tem | Avaliação |
|---|---|---|
| Modelo | Positivo S14BW01, BIOS de 2016, UEFI | Notebook de entrada de 2016 |
| Processador | Intel Celeron N3010, 2 núcleos, 1,04 GHz, 64 bits | **Muito fraco.** Não pode ser trocado (soldado). Estava em 90% de uso |
| RAM | **2 GB** DDR3 1600 (1 pente Samsung) — 2 slots, máx. 8 GB | **Gargalo nº 2.** Só 0,2 GB livre com o Windows parado |
| Disco | **HD mecânico** WD 500 GB (WD5000LPCX, 5400 rpm), SMART ok | **Gargalo nº 1.** Causa principal do boot lento e dos apps travando |
| Vídeo | Intel HD Graphics (integrada), tela 1366×768 | Ok para uso básico |
| Rede | Wi‑Fi Intel AC 3160 (dual band) + cabo Realtek | Ok |
| Bateria | 97% da capacidade original | Ótima |
| Sistema | Windows 10 Home SL **build 17134 (versão 1803, de 2018)** | Desatualizado há anos, sem suporte |

## Por que está tão lento

1. **HD mecânico + 2 GB de RAM**: com 2 GB, o Windows 10 usa o disco como memória
   o tempo todo, e o HD de 5400 rpm é lentíssimo para isso. Boot medido: **de 131 a 410 segundos** (2 a 7 minutos).
2. **Windows 10 1803**: versão de 2018 que não recebe atualizações há anos e não aceita Windows 11
   (processador não suportado).
3. **Processador Celeron N3010**: é o limite de desempenho que não dá para mudar.
   Mesmo depois das melhorias, o notebook vai servir para **uso leve**: navegador, documentos, vídeo e estudo.

## Plano

### Etapa 1: Peças (maior ganho por real gasto)
- **SSD SATA 2,5" de 240/256 GB** no lugar do HD. É o maior ganho: o boot cai de minutos para segundos.
  Confirmar ao abrir que o HD é de 2,5" SATA, o padrão desse modelo.
- **+1 pente de 4 GB DDR3L 1600 SODIMM** no slot livre, chegando a 6 GB. Confirmar ao abrir
  que o 2º slot existe de fato: o Windows diz que há 2, mas alguns Positivo vêm com só um soldado na placa.
- O HD antigo de 500 GB pode virar armazenamento externo com um case USB.

### Etapa 2: Sistema operacional (decidir antes de instalar)
| Opção | Prós | Contras |
|---|---|---|
| **Linux Mint XFCE** (ou Zorin OS Lite) | Leve, gratuito, com suporte até ~2029, atualizações seguras, roda bem em 2–4 GB | Office da Microsoft não roda (usa LibreOffice/Office online). Muda o costume do dono |
| **Windows 10 22H2 limpo + otimização** | Familiar, roda o Office 2016 que ele já tem | O suporte do Windows 10 acabou em out/2025. Mais pesado. Com 2 GB fica no limite: precisa do upgrade de RAM |

Não usar "Windows modificados" (Tiny10 e similares) baixados de sites desconhecidos: é risco de vírus.

### Etapa 3: Instalação limpa e ajustes
- Backup do que importar, mas a partição `D:` está vazia e `C:` tem poucos programas.
- Pendrive de instalação, instalação limpa no SSD e drivers.
- Inicialização enxuta: tirar OneDrive e atualizadores, navegador leve com bloqueador de anúncios.
- Medir de novo, com o mesmo script de inventário, para comparar antes e depois no vídeo.
