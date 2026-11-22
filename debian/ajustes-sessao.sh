#!/bin/sh
# ajustes-sessao.sh - Firefox e area de trabalho Xfce para o notebook Positivo S14BW01
# Uso:  sudo sh ajustes-sessao.sh <usuario>
# Parte 1 roda como root (sistema); parte 2 roda como o usuario, na sessao grafica dele.
set -e
U="${1:?informe o usuario}"
UID_U=$(id -u "$U")
passo() { echo; echo "### $*"; }

passo "1. Aceleracao de video: driver VA-API i965 (o iHD nao suporta este Celeron)"
grep -q '^LIBVA_DRIVER_NAME=' /etc/environment && sed -i 's/^LIBVA_DRIVER_NAME=.*/LIBVA_DRIVER_NAME=i965/' /etc/environment || echo 'LIBVA_DRIVER_NAME=i965' >> /etc/environment
grep LIBVA /etc/environment

passo "2. Firefox ESR: menos processos, video pela placa (H.264), menos escrita no HD"
F=/etc/firefox-esr/firefox-esr.js
sed -i '/^\/\/ >>> pc-seguidor/,/^\/\/ <<< pc-seguidor/d' "$F"
cat >> "$F" <<'EOF'
// >>> pc-seguidor: ajustes para Celeron N3010 + 2 GB RAM + HD 5400 rpm
// Menos processos de conteudo = menos RAM (padrao: 8)
pref("dom.ipc.processCount", 2);
// Libera memoria de abas paradas quando a RAM aperta
pref("browser.tabs.unloadOnLowMemory", true);
// Video decodificado pela placa (VA-API); a placa so faz H.264/VP8/HEVC
pref("media.ffmpeg.vaapi.enabled", true);
pref("media.hardware-video-decoding.force-enabled", true);
// YouTube: sem VP9/AV1 ele manda H.264, que a placa decodifica (o CPU nao da conta de VP9)
pref("media.mediasource.vp9.enabled", false);
pref("media.av1.enabled", false);
// Salva a sessao a cada 60 s (padrao 15 s) = menos escrita no HD
pref("browser.sessionstore.interval", 60000);
// Sem pre-carregamento de links/DNS
pref("network.prefetch-next", false);
pref("network.dns.disablePrefetch", true);
// Sem Pocket e sem conteudo patrocinado na nova aba
pref("extensions.pocket.enabled", false);
pref("browser.newtabpage.activity-stream.showSponsored", false);
pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
// <<< pc-seguidor
EOF
sed -n '/>>> pc-seguidor/,/<<< pc-seguidor/p' "$F" | grep -c '^pref' | sed 's/^/preferencias aplicadas: /'

passo "3. Xfce: sem sombras de janela (compositor fica ligado para o video nao rasgar)"
run_u() { sudo -u "$U" env DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$UID_U/bus "$@"; }
for p in show_frame_shadow show_popup_shadow show_dock_shadow; do
  run_u xfconf-query -c xfwm4 -p /general/$p -n -t bool -s false
  echo "$p = $(run_u xfconf-query -c xfwm4 -p /general/$p)"
done

passo "4. Xfce: tirar da inicializacao o que nao serve aqui"
# print-applet: icone de fila de impressao (39 MB); xfce4-notes: notas adesivas; xiccd: perfil de cor
A=/home/$U/.config/autostart
sudo -u "$U" mkdir -p "$A"
for n in print-applet xfce4-notes-autostart xiccd; do
  if [ -f /etc/xdg/autostart/$n.desktop ]; then
    printf '[Desktop Entry]\nHidden=true\n' | sudo -u "$U" tee "$A/$n.desktop" >/dev/null
    echo "desligado: $n"
  fi
done

echo; echo "### AJUSTES DE SESSAO CONCLUIDOS $(date '+%Y-%m-%d %H:%M:%S')"
