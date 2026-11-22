#!/bin/sh
# otimizar.sh - ajustes de desempenho para o notebook Positivo S14BW01
# (Celeron N3010, 2 GB RAM, HD 5400 rpm) com Debian 13 + Xfce.
# Roda como root. Pode ser executado mais de uma vez (idempotente).
# Cada bloco imprime "### <passo>" para o log versionado em relatorios/.
set -e
export DEBIAN_FRONTEND=noninteractive
passo() { echo; echo "### $*"; }

passo "1. Pacotes: zram, earlyoom, atualizacoes automaticas, uBlock Origin"
apt-get update -qq
apt-get install -y -qq zram-tools earlyoom unattended-upgrades webext-ublock-origin-firefox >/dev/null
echo "ok"

passo "2. zram: swap comprimida na RAM (zstd, 60% da RAM, prioridade acima do HD)"
cat > /etc/default/zramswap <<'EOF'
# pc-seguidor: swap comprimida na RAM para nao usar o HD lento como memoria
ALGO=zstd
PERCENT=60
PRIORITY=100
EOF
systemctl enable zramswap.service >/dev/null 2>&1
systemctl restart zramswap.service
swapon --show

passo "3. Memoria virtual ajustada para zram"
# Com zram, trocar para swap e barato (fica na RAM), entao swappiness alto e melhor.
# page-cluster=0: le 1 pagina por vez da zram (sem leitura antecipada inutil).
cat > /etc/sysctl.d/90-pc-seguidor.conf <<'EOF'
# pc-seguidor
vm.swappiness=150
vm.page-cluster=0
vm.vfs_cache_pressure=50
EOF
sysctl -q --system
sysctl vm.swappiness vm.page-cluster vm.vfs_cache_pressure

passo "4. earlyoom: fecha o processo que estourar a RAM antes do notebook congelar"
cat > /etc/default/earlyoom <<'EOF'
# pc-seguidor: age com 5% de RAM e 10% de swap livres; prefere fechar abas/navegador.
# Sem aspas e sem espacos nas regex: o systemd divide $EARLYOOM_ARGS por espaco e nao trata aspas.
EARLYOOM_ARGS="-m 5 -s 10 -r 3600 --prefer ^(firefox-esr|firefox|chromium|Web|Isolated) --avoid ^(Xorg|xfwm4|xfce4-panel|xfdesktop|lightdm|sshd|systemd)$"
EOF
systemctl enable earlyoom.service >/dev/null 2>&1
systemctl restart earlyoom.service
systemctl is-active earlyoom.service

passo "5. Servicos desnecessarios fora do boot"
# NetworkManager-wait-online: segurava o boot ~7s esperando a rede
# ModemManager: notebook nao tem modem 3G/4G
# cups-browsed + avahi: descoberta automatica de impressoras na rede (desliga; imprimir continua possivel)
# cups: passa a iniciar so quando alguem for imprimir (socket)
# e2scrub_reap: limpeza de snapshots LVM que nao existem aqui
for s in NetworkManager-wait-online.service ModemManager.service cups-browsed.service avahi-daemon.service avahi-daemon.socket e2scrub_reap.service; do
  systemctl disable --now "$s" >/dev/null 2>&1 && echo "desligado: $s" || echo "nao encontrado: $s"
done
systemctl disable cups.service >/dev/null 2>&1 && systemctl enable cups.socket >/dev/null 2>&1 && echo "cups: sob demanda (socket)"

passo "6. Disco: noatime (menos escritas no HD a cada leitura de arquivo)"
# O fstab padrao do Debian traz so "errors=remount-ro"; acrescenta noatime na linha da raiz (ext4)
[ -e /etc/fstab.antes-pc-seguidor ] || cp /etc/fstab /etc/fstab.antes-pc-seguidor
awk 'BEGIN{OFS="\t"} $0 !~ /^[[:space:]]*#/ && $2=="/" && $3=="ext4" && $4 !~ /(^|,)noatime(,|$)/ { $4="noatime," $4 } {print}' \
  /etc/fstab.antes-pc-seguidor > /etc/fstab.novo && mv /etc/fstab.novo /etc/fstab
grep -E '^[^#].*[[:space:]]/[[:space:]]+ext4' /etc/fstab
findmnt --verify --tab-file /etc/fstab >/dev/null && echo "fstab valido" || { echo "fstab INVALIDO - restaurando"; cp /etc/fstab.antes-pc-seguidor /etc/fstab; exit 1; }
mount -o remount,noatime /

passo "7. GRUB: menu de boot de 5s para 1s"
sed -i -E 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
grep '^GRUB_TIMEOUT' /etc/default/grub
update-grub 2>&1 | tail -1

passo "8. initramfs so com os modulos deste hardware (carrega menos do HD no boot)"
echo 'MODULES=dep' > /etc/initramfs-tools/conf.d/pc-seguidor
update-initramfs -u 2>&1 | tail -1
ls -lh /boot/initrd.img-$(uname -r) | awk '{print "initrd:", $5}'

passo "9. Atualizacoes de seguranca automaticas"
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
systemctl is-enabled unattended-upgrades.service

passo "10. Limpeza do cache do apt"
apt-get clean
echo "ok"

echo; echo "### OTIMIZACAO CONCLUIDA $(date '+%Y-%m-%d %H:%M:%S')"
