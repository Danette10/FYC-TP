#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  setup-ha-web.sh --role master|backup --ho-ip <IP> --vip <VIP> [options]

Required:
  --role       master or backup
  --ho-ip      Host-Only IP for this VM (e.g. 192.168.116.10)
  --vip        Virtual IP shared by both VMs (e.g. 192.168.116.100)

Options:
  --ho-iface   Host-Only interface (default: ens33)
  --nat-iface  NAT interface for internet/apt (default: ens34)
  --cidr       CIDR mask (default: 24)
  --vrid       VRRP virtual_router_id (default: 51)
  --auth-pass  VRRP password (<= 8 chars recommended, default: HaVrRp01)
  --prio-m     Master priority (default: 100)
  --prio-b     Backup priority (default: 90)
  -h, --help   Show this help

Examples:
  ./setup-ha-web.sh --role master --ho-ip 192.168.116.10 --vip 192.168.116.100
  ./setup-ha-web.sh --role backup --ho-ip 192.168.116.11 --vip 192.168.116.100
EOF
}

# Defaults
ROLE=""
HO_IP=""
VIP=""
HO_IFACE="ens33"
NAT_IFACE="ens34"
CIDR="24"
VRID="51"
AUTH_PASS="esgi"
PRIO_M="100"
PRIO_B="90"
SITE_DIR="/var/www/fyc"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) ROLE="${2:-}"; shift 2 ;;
    --ho-ip) HO_IP="${2:-}"; shift 2 ;;
    --vip) VIP="${2:-}"; shift 2 ;;
    --ho-iface) HO_IFACE="${2:-}"; shift 2 ;;
    --nat-iface) NAT_IFACE="${2:-}"; shift 2 ;;
    --cidr) CIDR="${2:-}"; shift 2 ;;
    --vrid) VRID="${2:-}"; shift 2 ;;
    --auth-pass) AUTH_PASS="${2:-}"; shift 2 ;;
    --prio-m) PRIO_M="${2:-}"; shift 2 ;;
    --prio-b) PRIO_B="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

# Checks
if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root: su -"
  exit 1
fi
if [[ "$ROLE" != "master" && "$ROLE" != "backup" ]]; then
  echo "Error: --role must be master|backup"
  usage; exit 1
fi
if [[ -z "$HO_IP" || -z "$VIP" ]]; then
  echo "Error: --ho-ip and --vip are required"
  usage; exit 1
fi
if [[ "${#AUTH_PASS}" -gt 8 ]]; then
  echo "Error: --auth-pass too long (${#AUTH_PASS}). Keep <= 8 chars."
  exit 1
fi

echo "[1/8] Fix APT sources (remove cdrom, add Debian repos)..."
SOURCES_LIST="/etc/apt/sources.list"
if [[ -f "$SOURCES_LIST" ]]; then
  sed -i 's/^\s*deb\s\+cdrom:/# deb cdrom:/g' "$SOURCES_LIST"
fi
cat > "$SOURCES_LIST" <<'EOF'
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF

echo "[2/8] Ensure NAT iface is up for apt ($NAT_IFACE)..."
ip link set "$NAT_IFACE" up || true
if command -v dhclient >/dev/null 2>&1; then
  dhclient -v "$NAT_IFACE" || true
fi

apt update
apt install -y nginx keepalived curl ifupdown

echo "[3/8] Configure Host-Only iface static ($HO_IFACE = $HO_IP/$CIDR)..."
cp -f /etc/network/interfaces "/etc/network/interfaces.bak.$(date +%s)" 2>/dev/null || true
cat > /etc/network/interfaces <<EOF
# Managed by setup-ha-web.sh
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto $HO_IFACE
iface $HO_IFACE inet static
  address $HO_IP/$CIDR
EOF

ip link set "$HO_IFACE" up || true
systemctl restart networking || true

echo "[4/8] Configure Nginx (same site on both + proof header)..."
mkdir -p "$SITE_DIR"
cat > "$SITE_DIR/index.html" <<'EOF'
<!doctype html>
<html lang="fr">
<head><meta charset="utf-8"><title>Mon site</title></head>
<body>
  <h1>Mon site</h1>
  <p>Ceci est un test</p>
</body>
</html>
EOF

sed -i "s#root /var/www/html;#root $SITE_DIR;#g" /etc/nginx/sites-available/default || true
cat > /etc/nginx/conf.d/servedby.conf <<EOF
add_header X-Served-By $ROLE always;
EOF
cat > /etc/nginx/conf.d/healthz.conf <<'EOF'
server {
  listen 127.0.0.1:8081;
  server_name _;
  location /healthz {
    add_header Content-Type text/plain;
    return 200 "ok\n";
  }
}
EOF

nginx -t
systemctl enable --now nginx
systemctl reload nginx

echo "[5/8] Install nginx healthcheck script..."
cat > /usr/local/bin/check_vip_ready.sh <<'EOF'
#!/usr/bin/env bash
# Keepalived healthcheck: nginx must answer HTTP 200 on local health endpoint
set -euo pipefail
curl -fsS --max-time 1 http://127.0.0.1:8081/healthz >/dev/null
EOF
chmod +x /usr/local/bin/check_vip_ready.sh

echo "[6/8] Configure Keepalived (VRRP + VIP)..."
STATE="BACKUP"; PRIO="$PRIO_B"
if [[ "$ROLE" == "master" ]]; then
  STATE="MASTER"; PRIO="$PRIO_M"
fi

cat > /etc/keepalived/keepalived.conf <<EOF
vrrp_script chk_vip_ready {
    script "/usr/local/bin/check_vip_ready.sh"
    interval 2
    fall 2
    rise 1
}

vrrp_instance VI_1 {
    state $STATE
    interface $HO_IFACE
    virtual_router_id $VRID
    priority $PRIO
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass $AUTH_PASS
    }

    virtual_ipaddress {
        $VIP/$CIDR
    }

    track_script {
        chk_vip_ready
    }
}
EOF

systemctl enable --now keepalived
systemctl restart keepalived

echo "[7/8] Show network state..."
echo "Host-Only ($HO_IFACE):"
ip -4 a show "$HO_IFACE" || true
echo "VIP ($VIP) presence:"
ip -4 a | grep -F "$VIP" || true

echo "[8/8] Done. Test from host:"
echo "  curl -I http://$VIP | grep X-Served-By"
