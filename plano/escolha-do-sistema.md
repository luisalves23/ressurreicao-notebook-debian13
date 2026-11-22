# Escolha do sistema — sem trocar peças

Decisão de 2026-11-22: **o notebook fica com o hardware atual** (2 GB de RAM e HD de 5400 rpm).
Com isso, o que mais pesa na escolha é o **consumo de RAM com o PC parado** e a **quantidade
de coisas que o sistema lê do disco ao ligar**.

## Hardware conferido para Linux (pela rede, 2026-11-22)
| Peça | Dispositivo | Linux |
|---|---|---|
| Áudio | Realtek ALC269 (HDA) + HDMI Intel | Funciona direto |
| Wi‑Fi / Bluetooth | Intel Dual Band AC 3160 | Funciona; usa o firmware `firmware-iwlwifi`, que o instalador do Debian 13 já traz |
| Cabo de rede | Realtek RTL8168 | Funciona direto |
| Touchpad | Synaptics SMBus | Funciona direto |
| Webcam | VGA WebCam 04f2:b58d (UVC) | Funciona direto |
| Firmware | UEFI 64 bits, **Secure Boot ligado**, disco GPT | Debian e Mint dão boot com Secure Boot ligado |
| Dados | Pastas do usuário vazias e `D:` vazia | Não há o que salvar |

## Comparação
| | **Debian 13 mínimo + Xfce** | Linux Mint 22.3 Xfce | MX Linux 25 Xfce |
|---|---|---|---|
| Base | Debian 13.x "trixie" | Ubuntu 24.04 | Debian 13 |
| Suporte | Completo até **09/08/2028** e LTS até **30/06/2030** | Até **abril de 2029** | Segue o Debian 13 |
| RAM com o PC parado (aprox.) | **~450–550 MB** | ~800 MB–1 GB | ~600–700 MB |
| O que vem instalado | Só o que for escolhido | Muitos serviços e apps extras | Muitas ferramentas MX |
| Facilidade | Média (fica fácil depois de configurado) | **A mais fácil** | Fácil |

## Escolha: **Debian 13 instalado pelo *netinst* com Xfce**
- **Menos RAM ocupada**: com 2 GB, cada 300 MB a mais livres é a diferença entre o navegador abrir ou travar.
- **Menos leitura de disco**: instalação mínima, sem serviços sobrando, liga mais rápido no HD lento.
- **Suporte mais longo** que o Mint: atualizações de segurança até 2030.
- O Xfce é estável e completo no Debian. O LXQt é um pouco mais leve, e fica como plano B se precisar.

### Ajustes depois de instalar (feitos daqui, pela rede, via SSH)
- **zram**: comprime a memória, e o PC passa a usar menos o HD como memória extra. É o ajuste mais importante.
- `swappiness` baixo, `noatime` no disco e menos serviços na inicialização.
- Firefox ESR com uBlock Origin, para que os anúncios não gastem memória.
- LibreOffice para documentos, já que o Office 2016 não roda no Linux.
- Atualização automática de segurança (`unattended-upgrades`).

### Observação
A licença do Windows 10 desse Positivo é OEM e fica gravada na placa. Se um dia ele quiser
voltar para o Windows, ela é reconhecida sozinha.

Fontes: [Debian trixie](https://www.debian.org/releases/trixie/), [Linux Mint 22.3](https://linuxmint.com/rel_zena_whatsnew.php), [MX Linux 25](https://linuxiac.com/mx-linux-25-officially-released-with-debian-13-base/).
