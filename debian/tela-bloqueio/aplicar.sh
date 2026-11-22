#!/bin/bash
# aplicar.sh - tela de bloqueio/login estilo macOS (lightdm-gtk-greeter + light-locker)
# Uso: sudo bash aplicar.sh <usuario> <pasta-com-avatar.svg-e-gtk.css>
set -e
U="${1:?usuario}"; SRC="${2:?pasta}"
FOTO=/usr/share/backgrounds/pc-seguidor/vernazza.jpg
DESF=/usr/share/backgrounds/pc-seguidor/vernazza-desfocado.jpg
passo() { echo; echo "### $*"; }

passo "1. Fundo desfocado (gerado uma vez; nada e calculado na hora de bloquear)"
ffmpeg -nostdin -loglevel error -y -i "$FOTO" -vf "gblur=sigma=28,eq=brightness=-0.06:saturation=1.15" -q:v 3 "$DESF"
chmod 644 "$DESF"; ls -lh "$DESF" | awk '{print "  ", $NF, $5}'

passo "2. Avatar do usuario (registrado no AccountsService; o greeter nao le a home, que e privada)"
INI=$(getent passwd "$U" | cut -d: -f5 | cut -d, -f1 | cut -c1 | tr '[:lower:]' '[:upper:]'); INI=${INI:-$(echo "$U" | cut -c1 | tr '[:lower:]' '[:upper:]')}
sed "s/INICIAL/$INI/" "$SRC/avatar.svg" > /tmp/avatar.svg
rsvg-convert -w 256 -h 256 /tmp/avatar.svg -o /tmp/avatar.png
install -m 644 /tmp/avatar.png /var/lib/AccountsService/icons/"$U"
UID_U=$(id -u "$U")
busctl call org.freedesktop.Accounts /org/freedesktop/Accounts/User$UID_U org.freedesktop.Accounts.User SetIconFile s /var/lib/AccountsService/icons/"$U" 2>/dev/null || true
install -o "$U" -g "$U" -m 644 /tmp/avatar.png /home/"$U"/.face
grep -E '^Icon=' /var/lib/AccountsService/users/"$U" | sed 's/^/  /'

passo "3. Configuracao do greeter"
C=/etc/lightdm/lightdm-gtk-greeter.conf
[ -e "$C.antes-pc-seguidor" ] || cp "$C" "$C.antes-pc-seguidor"
cat > "$C" <<EOF
# pc-seguidor: tela de bloqueio/login estilo macOS (original em $C.antes-pc-seguidor)
[greeter]
background=$DESF
user-background=false
theme-name=Arc-Dark
icon-theme-name=elementary-xfce-dark
font-name=Sans 11
xft-antialias=true
xft-hintstyle=hintslight
xft-rgba=rgb
indicators=~spacer;~clock;~spacer;~power
clock-format=%A, %d de %B    %H:%M
position=50%,center 52%,center
panel-position=top
hide-user-image=false
round-user-image=true
screensaver-timeout=60
EOF
grep -vE '^#' "$C" | sed 's/^/  /'

passo "4. CSS do greeter (aparencia: vidro, avatar redondo, sem caixas)"
D=/var/lib/lightdm/.config/gtk-3.0
mkdir -p "$D"; install -m 644 "$SRC/gtk.css" "$D/gtk.css"; chown -R lightdm:lightdm /var/lib/lightdm/.config
ls -l "$D/gtk.css" | awk '{print "  ", $NF, $5" bytes"}'

passo "5. Mostrar o usuario (nome + avatar) em vez de pedir para digitar o nome"
# O Debian vem com greeter-hide-users=true: aparece uma caixa de usuario e nenhum avatar.
mkdir -p /etc/lightdm/lightdm.conf.d
printf '[Seat:*]\ngreeter-hide-users=false\n' > /etc/lightdm/lightdm.conf.d/50-pc-seguidor.conf
cat /etc/lightdm/lightdm.conf.d/50-pc-seguidor.conf | sed 's/^/  /'

echo; echo "### TELA DE BLOQUEIO APLICADA $(date '+%Y-%m-%d %H:%M:%S')"
