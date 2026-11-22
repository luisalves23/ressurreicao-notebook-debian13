#!/bin/bash
# demo-apps.sh - grava a tela mostrando os apps abrindo pelo dock, com cronometro de abertura.
# Ordem: Arquivos, Firefox + YouTube, Terminal (fastfetch + efeito Matrix), Claude Code,
#        LibreOffice Writer, Editor de texto, Configuracoes e, no fim, um terminal com os tempos medidos.
# Uso (como o usuario da sessao grafica): bash demo-apps.sh <nome-do-video>
# Depende de: ~/demo-gravacao.sh (funcoes de mouse "de mao"), ffmpeg, xdotool, wmctrl, cmatrix, fastfetch
set -u
NOME="${1:?informe o nome}"
export DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus XDG_SESSION_TYPE=x11
W=1366; H=768
eval "$(sed -n '/^mover() {/,/^}/p;/^vaguear() {/,/^}/p' "$HOME/demo-gravacao.sh")"   # mesmo mouse organico
DIR="$(xdg-user-dir VIDEOS 2>/dev/null)"; [ -n "$DIR" ] && [ "$DIR" != "$HOME" ] || DIR="$HOME/Videos"
mkdir -p "$DIR"; OUT="$DIR/$NOME.mp4"
LOG="$HOME/velocidade-apps.txt"
echo "Tempo de abertura (primeira vez apos ligar, gravando a tela ao mesmo tempo) - $(date '+%d/%m/%Y %H:%M')" > "$LOG"

# centro de cada icone do dock (Plank, 8 itens, medido na tela 1366x768)
DOCK_Y=739
dock_x() { echo $(( 497 + ($1 - 1) * 53 )); }

# leva o mouse ate o dock (encosta na borda para ele aparecer, se estiver escondido) e clica no item N
clicar_dock() {
  local x; x=$(dock_x "$1")
  vaguear $((x + RANDOM % 60 - 30)) $((H - 1)); sleep 0.5
  vaguear "$x" "$DOCK_Y"; sleep 0.6
  xdotool click 1
}
# espera a janela aparecer e registra o tempo desde o clique
cronometrar() { # cronometrar "<nome no relatorio>" <--class|--name> <padrao>
  local t0 t1 ms; t0=$(date +%s%N)
  timeout 90 xdotool search --sync --onlyvisible "$2" "$3" >/dev/null 2>&1
  t1=$(date +%s%N); ms=$(( (t1 - t0) / 1000000 ))
  printf '  %-26s %5d.%01d s\n' "$1" $((ms / 1000)) $(((ms % 1000) / 100)) >> "$LOG"
}
digitar() { xdotool type --delay "${2:-70}" "$1"; }

wmctrl -l | awk '$NF!="xfce4-panel" && $NF!="plank" && $0 !~ /rea de trabalho/{print $1}' | xargs -r -n1 wmctrl -i -c
xdotool mousemove $((W / 2)) $((H / 2)); sleep 1

ffmpeg -nostdin -loglevel error -y -f x11grab -framerate 15 -video_size ${W}x${H} -i :0.0 \
  -c:v libx264 -preset ultrafast -crf 30 -pix_fmt yuv420p "$OUT" &
FF=$!
sleep 3

# 1. Arquivos
clicar_dock 1; cronometrar "Arquivos (Thunar)" --class Thunar; sleep 2
vaguear 300 160 520 170 760 175 640 300; sleep 1.5
xdotool key ctrl+w; sleep 1.5

# 2. Firefox + YouTube
clicar_dock 2; cronometrar "Firefox" --class firefox; sleep 4
xdotool key ctrl+l; sleep 0.4; digitar "youtube.com/watch?v=aqz-KE-bpKQ" 55; xdotool key Return
sleep 35; vaguear 700 380 480 450; xdotool click 1          # play (o Firefox bloqueia autoplay com som)
sleep 25; vaguear 520 420 640 300; sleep 2
xdotool key ctrl+q; sleep 5

# 3. Terminal: fastfetch + efeito Matrix
clicar_dock 3; cronometrar "Terminal" --class Xfce4-terminal; sleep 1.5
digitar "fastfetch"; xdotool key Return; sleep 7
digitar "cmatrix -b -u 4" 80; xdotool key Return; sleep 12
xdotool key q; sleep 1; digitar "exit"; xdotool key Return; sleep 2

# 4. Claude Code (vai pedir login: a conta e do seguidor)
clicar_dock 4; cronometrar "Claude Code (janela)" --name "Claude Code"; sleep 30   # o claude leva ~20 s para desenhar aqui
xdotool key ctrl+c; sleep 0.6; xdotool key ctrl+c; sleep 2; digitar "exit"; xdotool key Return; sleep 2

# 5. LibreOffice Writer
clicar_dock 5; cronometrar "LibreOffice Writer" --name "LibreOffice Writer"; sleep 5
vaguear 400 300 700 260 900 420; sleep 2
wmctrl -c "LibreOffice Writer"; sleep 4

# 6. Editor de texto: digita e desfaz (volta ao original e fecha sem a pergunta "salvar?")
clicar_dock 6; cronometrar "Editor de texto" --class Mousepad; sleep 1.5
digitar "Este notebook voltou a vida com Debian 13 + Xfce :)" 65; sleep 3
for i in $(seq 1 40); do xdotool key ctrl+z; sleep 0.05; done; sleep 1
xdotool key ctrl+q; sleep 2

# 7. Configuracoes
clicar_dock 7; cronometrar "Configuracoes" --class Xfce4-settings-manager; sleep 3
vaguear 300 200 600 260 900 240; sleep 2
wmctrl -c :ACTIVE:; sleep 2

# 8. Resultado dos tempos num terminal
clicar_dock 3; timeout 60 xdotool search --sync --onlyvisible --class Xfce4-terminal >/dev/null; sleep 1.5
digitar "clear; cat ~/velocidade-apps.txt" 45; xdotool key Return; sleep 10
digitar "exit"; xdotool key Return; sleep 2

vaguear 640 420 700 $((H - 30)); sleep 2
kill -INT $FF; wait $FF 2>/dev/null
echo "== tempos =="; cat "$LOG"
ls -lh "$OUT" | awk '{print "gravado:", $NF, $5}'
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT" | awk '{printf "duracao: %.0f s\n",$1}'
