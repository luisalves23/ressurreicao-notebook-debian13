#!/bin/bash
# dock-plank.sh - dock estilo Mac com o Plank (Debian 13 + Xfce)
#  - zoom nos icones ao passar o mouse
#  - esconde quando uma janela encosta nele (app maximizado/tela cheia) e volta ao levar o mouse para baixo
#  - tema proprio "Vidro": translucido, cantos arredondados, borda clara
#  - substitui o painel de baixo do Xfce; o painel de cima fica translucido (estilo barra do Mac)
# Uso: bash dock-plank.sh   (como o usuario da sessao grafica; usa sudo so para o apt)
set -e
export DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus
# Sem isto o Plank aberto via SSH morre com "Only X11 environments are supported"
export XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=XFCE XDG_SESSION_DESKTOP=xfce DESKTOP_SESSION=xfce
passo() { echo; echo "### $*"; }

passo "1. Instalar o Plank"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq plank >/dev/null
plank --version 2>/dev/null | head -1 || dpkg -s plank | grep '^Version'

passo "2. Tema 'Vidro'"
T="$HOME/.local/share/plank/themes/Vidro"; mkdir -p "$T"
cat > "$T/dock.theme" <<'EOF'
# Tema "Vidro" - projeto PC do Seguidor. Cores: vermelho;;verde;;azul;;opacidade (0-255)
# Paddings do Plank sao em DECIMOS do tamanho do icone (padrao 2.5). v1 usava 6/4/6/7 = dock enorme e espalhado.
[PlankTheme]
TopRoundness=11
BottomRoundness=11
LineWidth=1
# borda escura sutil: define o vidro tambem sobre janelas brancas
OuterStrokeColor=0;;0;;0;;55
FillStartColor=255;;255;;255;;78
FillEndColor=240;;242;;255;;58
# reflexo claro por dentro da borda (efeito vidro)
InnerStrokeColor=255;;255;;255;;95

[PlankDockTheme]
HorizPadding=1.2
TopPadding=1.4
BottomPadding=1.4
ItemPadding=2
IndicatorSize=2.6
IconShadowSize=1
UrgentBounceHeight=0.8
LaunchBounceHeight=0.3
FadeOpacity=1
ClickTime=250
UrgentBounceTime=600
LaunchBounceTime=500
ActiveTime=250
SlideTime=200
FadeTime=200
HideTime=200
GlowSize=20
GlowTime=10000
GlowPulseTime=2000
UrgentHueShift=150
ItemMoveTime=350
CascadeHide=true
EOF
echo "tema em $T"

passo "3. Atalho do Claude Code (abre o terminal ja dentro do claude)"
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/claude-code.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Claude Code
Comment=Assistente de programacao no terminal
Exec=xfce4-terminal --title "Claude Code" --working-directory=HOME_DIR -x bash -lc "claude; exec bash"
Icon=pc-seguidor-claude-code
Terminal=false
Categories=Development;
EOF
sed -i "s|HOME_DIR|$HOME|" "$HOME/.local/share/applications/claude-code.desktop"
echo "ok"

# Arquivos com o icone "rosto do Finder" tambem parado. NAO copiar o thunar.desktop (v2 fez isso e o Plank
# deixou de casar a janela do Thunar com o atalho: aparecia um icone extra). Em vez disso, o icone
# org.xfce.thunar do tema WhiteSur (instalado na pasta do usuario) passa a apontar para o do Finder.
rm -f "$HOME/.local/share/applications/thunar.desktop"
for d in "$HOME"/.local/share/icons/WhiteSur*/apps/scalable; do
  [ -f "$d/system-file-manager.svg" ] && ln -sf system-file-manager.svg "$d/org.xfce.thunar.svg"
done
for t in "$HOME"/.local/share/icons/WhiteSur*; do gtk-update-icon-cache -q -f -t "$t" 2>/dev/null || true; done

passo "4. Itens do dock"
# Fechar o Plank ANTES de mexer nos atalhos: aberto, ele reage a cada arquivo apagado/criado,
# remove itens e reordena a lista sozinho (aconteceu na v2).
pkill -x plank 2>/dev/null || true; sleep 1
L="$HOME/.config/plank/dock1/launchers"; mkdir -p "$L"; rm -f "$L"/*.dockitem
item() { printf '[PlankDockItemPreferences]\nLauncher=%s\n' "$2" > "$L/$1.dockitem"; echo "  $1"; }
item 01-arquivos   file:///usr/share/applications/thunar.desktop
item 02-firefox    file:///usr/share/applications/firefox-esr.desktop
item 03-terminal   file:///usr/share/applications/xfce4-terminal.desktop
item 04-claude     "file://$HOME/.local/share/applications/claude-code.desktop"
item 05-writer     file:///usr/share/applications/libreoffice-writer.desktop
item 06-editor     file:///usr/share/applications/org.xfce.mousepad.desktop
item 07-ajustes    file:///usr/share/applications/xfce-settings-manager.desktop
item 08-lixeira    docklet://trash

passo "5. Configuracao do dock (zoom, esconder, tema)"
S=net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/
gsettings set $S dock-items "['01-arquivos.dockitem','02-firefox.dockitem','03-terminal.dockitem','04-claude.dockitem','05-writer.dockitem','06-editor.dockitem','07-ajustes.dockitem','08-lixeira.dockitem']"
gsettings set $S theme 'Vidro'
gsettings set $S position 'bottom'
gsettings set $S alignment 'center'
gsettings set $S icon-size 42
gsettings set $S zoom-enabled true
gsettings set $S zoom-percent 128     # v1: 165% = exagerado
gsettings set $S hide-mode 'window-dodge'     # some quando uma janela encosta (ex.: maximizada)
gsettings set $S hide-delay 300
gsettings set $S unhide-delay 0
gsettings set $S pressure-reveal false
gsettings set $S show-dock-item false
gsettings set $S lock-items false
for k in theme icon-size zoom-enabled zoom-percent hide-mode; do echo "  $k = $(gsettings get $S $k)"; done

passo "6. Plank inicia junto com a sessao"
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/plank.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
X-GNOME-Autostart-enabled=true
EOF
echo "ok"

passo "7. Painel do Xfce: tira o de baixo, deixa o de cima translucido"
B="$HOME/.config/pc-seguidor-backup"; mkdir -p "$B"
cp -n "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" "$B/" 2>/dev/null || true
# ATENCAO: nunca usar "-rR" em /panels: o -R apaga recursivamente /panels/panel-1/* (o painel de cima inteiro).
# Basta regravar o array com um unico item (-a forca array).
if xfconf-query -c xfce4-panel -p /panels | tail -n +3 | grep -qx 2; then
  xfconf-query -c xfce4-panel -p /panels -a -t int -s 1
fi
echo "  paineis: $(xfconf-query -c xfce4-panel -p /panels | tail -n +3 | tr '\n' ' ')"
xfconf-query -c xfce4-panel -p /panels/panel-1/background-style -n -t uint -s 1
# barra escura translucida (estilo barra do Mac sobre foto); a clara (v1) deixava o texto ilegivel
xfconf-query -c xfce4-panel -p /panels/panel-1/background-rgba -n -a \
  -t double -s 0.06 -t double -s 0.06 -t double -s 0.09 -t double -s 0.45
xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t uint -s 26
# so menu (1), espacador (3), bandeja (6), relogio (8) e acoes (10): sem lista de janelas e sem areas de trabalho
xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -a -t int -s 1 -t int -s 3 -t int -s 6 -t int -s 7 -t int -s 8 -t int -s 9 -t int -s 10
xfconf-query -c xfce4-panel -p /plugins/plugin-3/expand -n -t bool -s true
xfconf-query -c xfce4-panel -p /plugins/plugin-3/style -n -t uint -s 0
xfce4-panel -r >/dev/null 2>&1 &
sleep 3

passo "8. Area de trabalho limpa (lixeira foi para o dock)"
for k in show-home show-filesystem show-trash; do
  xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/$k -n -t bool -s false
done
echo "ok"

passo "9. Iniciar o dock"
pkill -x plank 2>/dev/null || true; sleep 1
setsid plank >/tmp/plank.log 2>&1 < /dev/null &
sleep 4; pgrep -x plank >/dev/null && echo "plank rodando (pid $(pgrep -x plank), $(( $(ps -o rss= -p $(pgrep -x plank)) / 1024 )) MB)"

echo; echo "### DOCK CONCLUIDO $(date '+%Y-%m-%d %H:%M:%S')"
