#!/bin/sh
# medir.sh - fotografia do desempenho do Debian (somente leitura)
# Uso: ssh ... 'sudo sh -s' < debian/medir.sh
echo "=== MEDICAO $(date '+%Y-%m-%d %H:%M:%S') | $(hostname) | Debian $(cat /etc/debian_version) | kernel $(uname -r)"
echo; echo "=== Tempo de boot"
systemd-analyze 2>/dev/null
echo; echo "=== Top 15 servicos mais lentos no boot"
systemd-analyze blame 2>/dev/null | head -15
echo; echo "=== Cadeia critica"
systemd-analyze critical-chain 2>/dev/null | head -20
echo; echo "=== Memoria (MB)"
free -m
echo; echo "=== Swap"
swapon --show
cat /proc/sys/vm/swappiness | sed 's/^/swappiness=/'
echo; echo "=== Top 12 processos por memoria (RSS MB)"
ps -eo rss,comm --sort=-rss | head -13 | awk 'NR==1{print "   MB  PROCESSO";next}{printf "%5d  %s\n",$1/1024,$2}'
echo; echo "=== Servicos habilitados"
systemctl list-unit-files --type=service --state=enabled --no-legend | awk '{print $1}'
echo; echo "=== Timers"
systemctl list-timers --all --no-legend | awk '{print $(NF-1)}'
echo; echo "=== Disco"
df -h / | tail -1
findmnt -no OPTIONS /
echo; echo "=== Pacotes instalados: $(dpkg -l | grep -c '^ii')"
for p in firefox-esr chromium libreoffice-writer zram-tools earlyoom unattended-upgrades webext-ublock-origin-firefox flatpak cups bluez modemmanager avahi-daemon exim4-base; do
  dpkg -s "$p" >/dev/null 2>&1 && echo "  [instalado] $p" || echo "  [ausente]   $p"
done
