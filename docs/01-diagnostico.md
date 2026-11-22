# 01 — Diagnóstico

Fonte primária: [`relatorios/inventario-DESKTOP-BBF5M1P-20261122-1244.txt`](../relatorios/inventario-DESKTOP-BBF5M1P-20261122-1244.txt),
coletado **remotamente** com [`scripts/coletar-hardware.ps1`](../scripts/coletar-hardware.ps1) (somente leitura, compatível com PowerShell 2.0).

## Relato inicial
- O notebook **não ligava**. Depois de mexido pelo dono, voltou a ligar.
- Levava minutos para iniciar. Os aplicativos demoravam a abrir, e muitos nem abriam (o terminal levou ~3 min).

## Hardware

| Componente | Detalhe | Avaliação |
|---|---|---|
| Modelo | Positivo Informática S14BW01, BIOS AMI 1.06.X (08/2016), UEFI 64 bits, Secure Boot ligado, disco GPT | Notebook de entrada (2016) |
| CPU | Intel Celeron **N3010** (Braswell), 2 núcleos/2 threads, 1,04 GHz, 64 bits, VT‑x | Fraca e soldada: é o teto fixo de desempenho |
| RAM | **2 GB** DDR3‑1600 (1× Samsung M471B5674EB0‑YK0); 2 slots, máx. 8 GB | Gargalo nº 2: 0,2 GB livres com o Windows parado |
| Armazenamento | **HD WD5000LPCX** 500 GB, 5400 rpm, SATA. SMART: sem previsão de falha | Gargalo nº 1 |
| Vídeo | Intel HD Graphics (Gen8), 1366×768 | Decodifica H.264/VP8/HEVC por hardware (sem VP9/AV1) |
| Rede | Intel Dual Band Wireless‑AC 3160 + Realtek RTL8168 (cabo) + Bluetooth Intel | Bom suporte no Linux |
| Áudio | Realtek ALC269 (HDA) + HDMI Intel | Funciona direto no Linux |
| Entrada / câmera | Touchpad Synaptics SMBus; webcam UVC 04f2:b58d | Funcionam direto no Linux |
| Bateria | 97% da capacidade original | Ótima |

## Software (Windows)
- **Windows 10 Home Single Language, versão 1803 (build 17134)**, instalado em 05/2019 e **nunca atualizado**. Sem suporte, e não aceita o Windows 11 (CPU não suportada).
- Inicialização: OneDrive (2× instalador + cliente), Edge Update, Realtek, Synaptics, Windows Defender (`MsMpEng`, 238 MB).
- CPU em **90%** com o sistema parado. Office 2016 instalado. Pastas do usuário vazias.
- Log de eventos (30 dias): nenhum erro de disco (IDs 7/51/153) e nenhum desligamento inesperado (41/6008).

## Boot medido (log `Diagnostics-Performance`, evento 100)

| Data | Boot |
|---|---|
| 17/07/2024 | 131 s |
| 18/07/2024 | **410 s** |
| 24/07/2024 | 231 s |
| 30/07/2024 | 159 s |
| 11/08/2024 | 132 s |

## Conclusão
1. Com **2 GB de RAM**, o Windows 10 vive paginando no disco, e o **HD de 5400 rpm** torna cada paginação lenta. Daí o boot de minutos e os apps que não abrem.
2. O Windows 1803 está desatualizado e sem suporte.
3. Sem trocar peças, a alavanca é **o sistema**: um SO que caiba em ~500 MB e quase não use o disco como memória (zram).

O caminho ideal seria SSD + 4 GB de RAM ([plano/diagnostico-e-plano.md](../plano/diagnostico-e-plano.md)), mas o projeto foi feito **sem orçamento para peças**.
