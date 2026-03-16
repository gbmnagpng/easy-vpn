#!/bin/bash
set -e

# ─────────────────────────────────────────
#  Easy VPN Bootstrap
#  Stack: WGDashboard v4.3 + Traefik
#  Repo: https://github.com/gbmnagpng/easy-vpn
# ─────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/easy-vpn"
REPO_RAW="https://raw.githubusercontent.com/gbmnagpng/easy-vpn/main"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║          Easy VPN Installer                  ║"
echo "║   WGDashboard v4.3 + Traefik + DuckDNS SSL  ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Root check ──────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Este script precisa ser executado como root.${NC}"
  exit 1
fi

# ── OS check ────────────────────────────
if ! grep -qs "ubuntu" /etc/os-release; then
  echo -e "${RED}Este script requer Ubuntu 22.04 ou superior.${NC}"
  exit 1
fi
os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f2 | tr -d '.')
if [[ "$os_version" -lt 2204 ]]; then
  echo -e "${RED}Ubuntu 22.04 ou superior é necessário.${NC}"
  exit 1
fi

# ── Already installed? ───────────────────
if [ -f "$INSTALL_DIR/.env" ]; then
  echo -e "${YELLOW}Instalação existente detectada em $INSTALL_DIR${NC}"
  echo ""
  read -p "Reconfigurar e recriar tudo? [s/N]: " reinstall
  if [[ ! "$reinstall" =~ ^[sS]$ ]]; then
    echo "Saindo. Para gerenciar: cd $INSTALL_DIR && docker compose up -d"
    exit 0
  fi
  echo -e "${YELLOW}Parando containers existentes...${NC}"
  cd "$INSTALL_DIR" && docker compose down 2>/dev/null || true
fi

# ════════════════════════════════════════
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Passo 1 — Domínio DuckDNS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "O dashboard ficará acessível em:"
echo "  • https://wg.<domínio>"
echo ""
read -p "Domínio DuckDNS (ex: meusite.duckdns.org): " ROOT_DOMAIN
until [[ "$ROOT_DOMAIN" =~ ^[a-z0-9._-]+$ ]]; do
  echo -e "${RED}Domínio inválido.${NC}"
  read -p "Domínio DuckDNS: " ROOT_DOMAIN
done

# ════════════════════════════════════════
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Passo 2 — Token DuckDNS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Encontre seu token em: https://www.duckdns.org"
echo ""
read -p "Token DuckDNS: " DUCKDNS_TOKEN
until [[ ! -z "$DUCKDNS_TOKEN" ]]; do
  echo -e "${RED}Token não pode ser vazio.${NC}"
  read -p "Token DuckDNS: " DUCKDNS_TOKEN
done

# ════════════════════════════════════════
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Passo 3 — Usuário administrador${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Credenciais de acesso ao WGDashboard."
echo ""
read -p "Nome de usuário: " AUTH_USER
until [[ "$AUTH_USER" =~ ^[a-zA-Z0-9_]+$ ]]; do
  echo -e "${RED}Use apenas letras, números e underscore.${NC}"
  read -p "Nome de usuário: " AUTH_USER
done

echo ""
read -s -p "Senha (mín. 8 caracteres): " AUTH_PASSWORD
echo ""
until [[ ${#AUTH_PASSWORD} -ge 8 ]]; do
  echo -e "${RED}A senha precisa ter pelo menos 8 caracteres.${NC}"
  read -s -p "Senha: " AUTH_PASSWORD
  echo ""
done
read -s -p "Confirme a senha: " AUTH_PASSWORD2
echo ""
until [[ "$AUTH_PASSWORD" == "$AUTH_PASSWORD2" ]]; do
  echo -e "${RED}As senhas não coincidem.${NC}"
  read -s -p "Senha: " AUTH_PASSWORD
  echo ""
  read -s -p "Confirme: " AUTH_PASSWORD2
  echo ""
done

# ════════════════════════════════════════
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Instalando dependências...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y curl wget

# ── Docker ───────────────────────────────
if ! command -v docker &>/dev/null; then
  echo -e "${YELLOW}Instalando Docker...${NC}"
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
  echo -e "${GREEN}Docker instalado!${NC}"
else
  echo -e "${GREEN}Docker já instalado: $(docker --version)${NC}"
fi

# ── IP forwarding ────────────────────────
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-vpn.conf
sysctl -p /etc/sysctl.d/99-vpn.conf

# ── Criar estrutura de diretórios ─────────
mkdir -p "$INSTALL_DIR"/data/traefik

# ── Baixar arquivos do repositório ────────
echo -e "${YELLOW}Baixando arquivos do repositório...${NC}"
wget -q "$REPO_RAW/docker-compose.yml" -O "$INSTALL_DIR/docker-compose.yml"
wget -q "$REPO_RAW/data/traefik/traefik.yml" -O "$INSTALL_DIR/data/traefik/traefik.yml"
echo -e "${GREEN}Arquivos baixados!${NC}"

# ── .env ─────────────────────────────────
cat > "$INSTALL_DIR/.env" << EOF
ROOT_DOMAIN=${ROOT_DOMAIN}
DUCKDNS_TOKEN=${DUCKDNS_TOKEN}
AUTH_USER=${AUTH_USER}
AUTH_PASSWORD=${AUTH_PASSWORD}
EOF
chmod 600 "$INSTALL_DIR/.env"

# ── acme.json ─────────────────────────────
touch "$INSTALL_DIR/data/traefik/acme.json"
chmod 600 "$INSTALL_DIR/data/traefik/acme.json"

# ── Firewall ─────────────────────────────
if command -v ufw &>/dev/null; then
  echo -e "${YELLOW}Configurando firewall...${NC}"
  ufw allow 22/tcp    comment "SSH"       > /dev/null
  ufw allow 80/tcp    comment "HTTP"      > /dev/null
  ufw allow 443/tcp   comment "HTTPS"     > /dev/null
  ufw allow 51820/udp comment "WireGuard" > /dev/null
  ufw --force enable  > /dev/null
  echo -e "${GREEN}Firewall configurado!${NC}"
fi

# ════════════════════════════════════════
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Baixando e iniciando serviços...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
cd "$INSTALL_DIR"
docker compose pull
docker compose up -d

sleep 10

# ════════════════════════════════════════
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Instalação concluída! ✓                 ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  📡 WGDashboard:  ${CYAN}https://wg.${ROOT_DOMAIN}${NC}"
echo ""
echo -e "  👤 Usuário:  ${CYAN}${AUTH_USER}${NC}"
echo -e "  🔑 Senha:    ${CYAN}(a que você definiu)${NC}"
echo ""
echo -e "${YELLOW}  ⚠️  O certificado SSL pode levar 1-2 minutos na primeira vez.${NC}"
echo -e "${YELLOW}  ⚠️  No primeiro acesso configure o 2FA no WGDashboard.${NC}"
echo ""
echo -e "  Logs:    ${CYAN}cd $INSTALL_DIR && docker compose logs -f${NC}"
echo -e "  Status:  ${CYAN}cd $INSTALL_DIR && docker compose ps${NC}"
echo -e "  Parar:   ${CYAN}cd $INSTALL_DIR && docker compose down${NC}"
echo -e "  Atualizar: ${CYAN}cd $INSTALL_DIR && docker compose pull && docker compose up -d${NC}"
echo ""
