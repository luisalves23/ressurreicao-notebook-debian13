#!/bin/bash
# demo-gravacao.sh - grava a tela do notebook executando sempre o MESMO roteiro,
# para comparar antes x depois da customizacao.
# Uso (como o usuario da sessao grafica): bash demo-gravacao.sh <nome-do-arquivo>
# Saida: <pasta de videos do usuario>/<nome>.mp4  (ffmpeg x11grab, 15 fps, H.264 ultrafast)
set -u
NOME="${1:?informe o nome}"
export DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
# pasta de videos do usuario pelo xdg (sem acento escrito aqui: evita problema de codificacao)
DIR="$(xdg-user-dir VIDEOS 2>/dev/null)"; [ -n "$DIR" ] && [ "$DIR" != "$HOME" ] || DIR="$HOME/Videos"
mkdir -p "$DIR"; OUT="$DIR/$NOME.mp4"
W=1366; H=768
# mover x1 y1 x2 y2 [duracao_s]: movimento "de mao", nao em linha reta:
#  - curva de Bezier cubica com pontos de controle sorteados para os lados do trajeto
#  - acelera no comeco e freia no fim (easing), passos com tempo levemente irregular
#  - tremor de 1-2 px e, as vezes, passa um pouco do alvo e corrige
# Gera tudo numa unica chamada do xdotool (mais fluido que um processo por passo).
mover() {
  local x1=$1 y1=$2 x2=$3 y2=$4 dur=${5:-0.9}
  local cmd
  # LC_ALL=C: no sistema em pt_BR o awk escreveria "0,012" e o xdotool leria a pausa como zero
  cmd=$(LC_ALL=C awk -v x1="$x1" -v y1="$y1" -v x2="$x2" -v y2="$y2" -v dur="$dur" -v seed="$RANDOM$RANDOM" -v W="$W" -v H="$H" '
    function clamp(v,lo,hi){ return v<lo?lo:(v>hi?hi:v) }
    function ease(t){ return t<0.5 ? 4*t*t*t : 1-((-2*t+2)^3)/2 }
    function bez(a,b,c,d,t){ u=1-t; return u*u*u*a + 3*u*u*t*b + 3*u*t*t*c + t*t*t*d }
    function trecho(ax,ay,bx,by,d,   dx,dy,dist,nx,ny,c1x,c1y,c2x,c2y,n,i,t,e,px,py) {
      dx=bx-ax; dy=by-ay; dist=sqrt(dx*dx+dy*dy); if (dist<1) return
      nx=-dy/dist; ny=dx/dist                       # direcao perpendicular ao trajeto
      c1x=ax+dx*(0.2+rand()*0.2)+nx*dist*(rand()*0.36-0.18); c1y=ay+dy*(0.2+rand()*0.2)+ny*dist*(rand()*0.36-0.18)
      c2x=ax+dx*(0.6+rand()*0.2)+nx*dist*(rand()*0.30-0.15); c2y=ay+dy*(0.6+rand()*0.2)+ny*dist*(rand()*0.30-0.15)
      n=int(clamp(dist/9,12,90))
      for (i=1;i<=n;i++) {
        t=i/n; e=ease(t)
        px=bez(ax,c1x,c2x,bx,e)+(i<n ? rand()*2.4-1.2 : 0)
        py=bez(ay,c1y,c2y,by,e)+(i<n ? rand()*2.4-1.2 : 0)
        printf "mousemove %d %d sleep %.3f ", clamp(px,0,W-1), clamp(py,0,H-1), d/n*(0.7+rand()*0.6)
      }
    }
    BEGIN {
      srand(seed)
      if (rand()<0.45) {                             # passa um pouco do alvo e volta
        ox=x2+(x2-x1)*(0.03+rand()*0.04)+rand()*10-5; oy=y2+(y2-y1)*(0.03+rand()*0.04)+rand()*10-5
        trecho(x1,y1,ox,oy,dur*0.88); trecho(ox,oy,x2,y2,dur*0.22)
      } else trecho(x1,y1,x2,y2,dur)
    }')
  # shellcheck disable=SC2086
  xdotool $cmd
}
# vaguear x y [x y ...]: passa por varios pontos com pequenas pausas, como alguem explorando a tela
vaguear() {
  local px py
  px=$(xdotool getmouselocation | sed -E 's/x:([0-9]+) y:([0-9]+).*/\1/'); py=$(xdotool getmouselocation | sed -E 's/x:([0-9]+) y:([0-9]+).*/\2/')
  while [ $# -ge 2 ]; do
    mover "$px" "$py" "$1" "$2" "0.$((5 + RANDOM % 5))"; px=$1; py=$2; shift 2
    sleep "0.$((15 + RANDOM % 40))"
  done
}
esperar_janela() { xdotool search --sync --onlyvisible --class "$1" >/dev/null 2>&1; sleep "${2:-1}"; }

xdotool mousemove $((W/2)) $((H/2))
ffmpeg -nostdin -loglevel error -y -f x11grab -framerate 15 -video_size ${W}x${H} -i :0.0 \
  -c:v libx264 -preset ultrafast -crf 30 -pix_fmt yuv420p "$OUT" &
FF=$!
sleep 3                                              # 1. area de trabalho parada

vaguear 520 470 380 $((H-24))                        # 2. mouse passeia pela parte de baixo (painel / dock)
vaguear 520 $((H-30)) 640 $((H-22)) 760 $((H-28)) 900 $((H-24)) 1010 $((H-30))
sleep 1

xfce4-popup-applicationsmenu >/dev/null 2>&1 \
  || xfce4-popup-whiskermenu >/dev/null 2>&1         # 3. menu de aplicativos
sleep 3; xdotool key Escape; sleep 1

exo-open --launch FileManager >/dev/null 2>&1 &      # 4. gerenciador de arquivos
esperar_janela Thunar 2
wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz; sleep 3   # maximizado (o dock deve sumir)
vaguear 700 420 640 $((H-1)); sleep 2.5                           # mouse na borda de baixo (o dock deve voltar)
vaguear 560 $((H-28)) 690 $((H-24)) 820 $((H-30)); sleep 1
vaguear 760 520 690 380; sleep 2
wmctrl -c :ACTIVE:; sleep 2

xfce4-terminal >/dev/null 2>&1 &                     # 5. terminal + Claude Code
esperar_janela Xfce4-terminal 2
xdotool type --delay 90 "claude --version"; xdotool key Return; sleep 4
wmctrl -c :ACTIVE:; sleep 2

vaguear 610 460 700 $((H-26)); sleep 2              # 6. fim na area de trabalho
kill -INT $FF; wait $FF 2>/dev/null
ls -lh "$OUT" | awk '{print "gravado:", $NF, $5}'
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT" | awk '{printf "duracao: %.0f s\n",$1}'
