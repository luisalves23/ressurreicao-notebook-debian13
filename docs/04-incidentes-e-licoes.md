# 04 — Incidentes e lições (pós-mortems)

Formato: **sintoma → causa raiz → correção → prevenção**.

## 1. Ventoy bloqueado pelo Secure Boot
- **Sintoma:** boot pelo pendrive parou em *"Verification failed / Security Violation"*.
- **Causa:** o carregador do Ventoy não é assinado pela Microsoft. O Secure Boot estava ligado, e isso tinha sido detectado no inventário, mas não foi tratado antes do boot.
- **Correção:** desligar o Secure Boot na BIOS.
- **Prevenção:** checar `Confirm-SecureBootUEFI` antes. Alternativas: registrar a chave do Ventoy no MokManager, ou gravar a ISO com Rufus (modo DD), que dá boot com o Secure Boot ligado.
- **Desdobramento:** depois de um esgotamento total da bateria, a BIOS voltou ao padrão (Secure Boot ligado) e passou a barrar o próprio Debian (*"Invalid signature detected"*). Esta BIOS de 2016 não aceitou o shim do Debian. **Recomendação: manter o Secure Boot desligado neste modelo.**

## 2. "Travamento" que era a bateria acabando
- **Sintoma:** 6 minutos depois do login, o notebook sumiu da rede e não acordou com tecla. Foi desligado à força.
- **Primeira hipótese (errada):** bug de C‑states dos Celeron Braswell.
- **Evidência:** o `boot_id` e o `uptime` mostraram que **não houve reboot**: o sistema voltou de hibernação. No journal: `systemd-logind: The system will hybrid sleep now!` às 14:55:46. No histórico do UPower (`/var/lib/upower/history-charge-*`): 6% → 2% descarregando entre 14:49 e 14:55, e um "charging" de 1 s às 14:50 (**plugue do carregador possivelmente frouxo**).
- **Causa:** `CriticalPowerAction=HybridSleep` (padrão da UPower) a 2%. A suspensão drenou o resto, a bateria zerou e no religamento o sistema voltou da imagem gravada no HD.
- **Correção:** `CriticalPowerAction=Hibernate`, que desliga de verdade sem drenar.
- **Lição:** antes de culpar o hardware, cruzar journal, `boot_id` e histórico de energia.

## 3. Painel superior do Xfce apagado
- **Sintoma:** a barra de cima virou uma caixa vazia ([captura](img/08-erro-painel-apagado.png)).
- **Causa:** `xfconf-query -c xfce4-panel -p /panels -rR` — o `-R` (recursivo) apagou `/panels/panel-1/*` inteiro.
- **Correção:** restaurar o `xfce4-panel.xml` do backup (com `xfce4-panel --quit` e `xfconfd` parados) e regravar o array com `-a -t int -s 1`.
- **Prevenção:** fazer backup de qualquer canal xfconf antes de alterar. Nunca usar `-R` em `/panels`.

## 4. Dock: grande, espalhado, com ícone duplicado e ordem bagunçada
- **v1 grande/espaçada:** os paddings do tema do Plank são **décimos do tamanho do ícone**, e foram usados valores 6/4/6/7 (o padrão é 2,5). → 1,2/1,4/1,4/2; zoom de 165% → 128%.
- **Ícone extra do Thunar:** uma cópia local do `thunar.desktop` impediu o Plank de casar a janela com o atalho. → Trocar o ícone no tema (symlink no WhiteSur do usuário) em vez de copiar o `.desktop`.
- **Ordem bagunçada:** o script recriava os `.dockitem` **com o Plank aberto**, e ele reagia a cada arquivo, removendo e reordenando itens. → `pkill plank` antes de mexer.

## 5. uBlock Origin pesado demais para 2 GB
- **Sintoma:** Firefox levando 15,3 s para abrir, um processo de extensões com 572 MB e 52% de CPU, e ainda 344 MB / 30% depois de 3 min.
- **Causa:** o uBlock Origin (pacote `webext-ublock-origin-firefox` 1.67) recompila as listas a cada abertura.
- **Correção:** remoção do pacote. Firefox: **5,0 s** para abrir, ~10% de CPU parado.
- **Pendente:** o uBlock Origin **Lite** (MV3, usa o motor nativo do Firefox) foi configurado via `policies.json`, mas não instalou sozinho. Instalar à mão pelo addons.mozilla.org.

## 6. Pequenas armadilhas de automação
| Sintoma | Causa | Correção |
|---|---|---|
| Plank morre via SSH | "Only X11 environments are supported" | `XDG_SESSION_TYPE=x11` |
| Papel de parede não muda | Chaves antigas `monitor0`; o Xfce 4.20 usa o nome real (`monitoreDP-1`) | Gravar por `xrandr --listmonitors` |
| Avatar não aparece no greeter | `greeter-hide-users=true` (padrão do Debian) e home privada | `lightdm.conf.d` + AccountsService. **Só vale depois de reiniciar o LightDM** |
| `loginctl unlock-session` não volta à sessão | O light-locker não troca de VT sozinho | `chvt 7` (no uso normal, a senha resolve) |
| YouTube não toca na demo | Autoplay com som bloqueado | Clique no play |
| Sombras do papel de parede cortadas em linha reta | Região do filtro SVG pequena demais | `filterUnits="userSpaceOnUse"` |
