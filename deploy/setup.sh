#!/bin/bash
set -e

echo "═══════════════════════════════════════════════════"
echo "  GVH-AFFiNE + NocoDB — Hetzner VPS Setup"
echo "═══════════════════════════════════════════════════"

# Check Docker
if ! command -v docker &>/dev/null; then
    echo "Docker not found. Installing..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    echo "Docker installed. You may need to log out/in for group changes."
fi

# Check Docker Compose
if ! docker compose version &>/dev/null; then
    echo "ERROR: docker compose not available. Update Docker or install compose plugin."
    exit 1
fi

# Create NocoDB database on shared Postgres
echo ""
echo "Starting Postgres first to create NocoDB database..."
docker compose up -d postgres
echo "Waiting for Postgres to be healthy..."
sleep 5

# Source .env for the password
source .env

# Create nocodb database if it doesn't exist
docker compose exec postgres psql -U "${DB_USERNAME:-affine}" -tc \
    "SELECT 1 FROM pg_database WHERE datname = 'nocodb'" | grep -q 1 \
    || docker compose exec postgres psql -U "${DB_USERNAME:-affine}" -c "CREATE DATABASE nocodb"

echo "NocoDB database ready."

# Start everything
echo ""
echo "Starting all services..."
docker compose up -d

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Waiting for services to initialize..."
echo "═══════════════════════════════════════════════════"
sleep 15

echo ""
echo "Service status:"
docker compose ps

VPS_IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_VPS_IP")

echo ""
echo "═══════════════════════════════════════════════════"
echo "  DONE! Access your apps:"
echo ""
echo "  AFFiNE:  http://${VPS_IP}/"
echo "  NocoDB:  http://${VPS_IP}/db/"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Open AFFiNE and create your account"
echo "  2. Open NocoDB and create your account"
echo "  3. Point a domain at ${VPS_IP} and add SSL with certbot"
