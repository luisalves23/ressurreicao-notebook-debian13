# PC do Seguidor — Ressurreição

Projeto de recuperação de um PC antigo de um seguidor: diagnóstico completo do
hardware, escolha de um sistema operacional leve e instalação otimizada para
dar mais vida útil à máquina.

## Situação inicial (relato)

- O PC **não ligava**; depois de mexido, **passou a ligar**.
- Demora muito para iniciar.
- Os aplicativos demoram para abrir e **muitos nem abrem**.

## Estrutura

| Caminho | Para que serve |
|---|---|
| `DIARIO.md` | Diário técnico: tudo o que foi feito no PC, em ordem, com data |
| `scripts/coletar-hardware.ps1` | Roda **no PC do seguidor** e gera o inventário completo de hardware/software |
| `scripts/liberar-acesso-remoto.ps1` | Roda **no PC do seguidor** (como Administrador) para permitir acesso pela rede |
| `relatorios/` | Inventários coletados (um por coleta, com data) |
| `plano/` | Plano de instalação do sistema leve (criado depois do diagnóstico) |

## Como funciona o acesso

1. Conectar o PC do seguidor no **mesmo Wi‑Fi/rede** deste PC (rede `192.168.100.x`).
2. No PC do seguidor, abrir o PowerShell **como Administrador** e rodar
   `scripts/liberar-acesso-remoto.ps1` (levar por pendrive).
3. Daqui, abrir a sessão remota com o usuário/senha do PC do seguidor
   (a senha é digitada por você, nunca fica salva no repositório).
4. Rodar `scripts/coletar-hardware.ps1` remotamente e salvar o resultado em `relatorios/`.

Plano B (sem rede): rodar `coletar-hardware.ps1` direto no PC do seguidor pelo
pendrive — ele grava o relatório ao lado do script — e trazer o arquivo para `relatorios/`.
