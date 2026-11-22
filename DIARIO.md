# Diário técnico

Registro em ordem cronológica de tudo o que foi feito. Cada entrada corresponde
a um ou mais commits no Git.

## 2026-11-22

### Início do projeto
- Criado o repositório para versionar todo o trabalho.
- Rede local deste PC (estação de trabalho): Wi‑Fi `192.168.100.149`, gateway `192.168.100.1`.

### Primeira varredura de rede
- Varridos todos os endereços `192.168.100.1–254` (ping + ARP + portas 22, 135, 139, 445, 3389, 5985).
- **Nenhum PC Windows encontrado além desta estação.** Os aparelhos ativos
  (.1, .7, .9, .22, .24, .26, .27, .29, .32, .45, .70, .81, .155) não têm
  portas de Windows abertas — são roteador, celulares, TVs e afins.
- Motivo: o PC do seguidor **ainda não foi conectado ao Wi‑Fi**.
- Próximo passo: conectar o PC na rede e rodar `scripts/liberar-acesso-remoto.ps1` nele.

### Ferramentas preparadas
- `scripts/coletar-hardware.ps1`: inventário só-leitura, testado nesta estação (estação de trabalho do autor) — rodou sem erros.
- `scripts/liberar-acesso-remoto.ps1`: liga WinRM no PC do seguidor, com firewall restrito à rede local e opção `-Desfazer`.
- Escolhido WinRM (PowerShell Remoting) em vez de SSH/AnyDesk: já vem no Windows 7/10, não precisa baixar nada no PC velho e é reversível.
