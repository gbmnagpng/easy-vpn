# 🔒 Easy VPN

Stack de VPN completa com WGDashboard v4.3 + Traefik + SSL automático via DuckDNS.

## Serviços

| Serviço | Função |
|---|---|
| **WGDashboard v4.3** | WireGuard VPN + Interface web completa com 2FA nativo |
| **Traefik** | Proxy reverso com SSL automático via DuckDNS |
| **Watchtower** | Atualizações automáticas dos containers |

## Pré-requisitos

- Ubuntu 22.04 ou 24.04
- Subdomínio DuckDNS apontando para o IP do servidor
- Portas **80**, **443** e **51820/UDP** abertas

## Instalação

```bash
# Clonar o projeto
git clone https://github.com/SEU_USUARIO/easy-vpn
cd easy-vpn

# Rodar o instalador
sudo bash bootstrap.sh
```

O script pergunta interativamente:
1. **Domínio DuckDNS** — ex: `meusite.duckdns.org`
2. **Token DuckDNS** — em [duckdns.org](https://www.duckdns.org)
3. **Usuário e senha** — admin do WGDashboard

## Após a instalação

Acesse: `https://wg.<seu-dominio>.duckdns.org`

No primeiro acesso o WGDashboard vai pedir pra configurar o 2FA (TOTP).

## O que o WGDashboard oferece

- ✅ Interface moderna em Vue.js com dark mode
- ✅ 2FA/TOTP nativo (Google Authenticator, Authy)
- ✅ Gráficos de tráfego por peer em tempo real
- ✅ Métricas do servidor (CPU, RAM, disco)
- ✅ Múltiplas interfaces WireGuard (wg0, wg1...)
- ✅ QR code e download de .conf por cliente
- ✅ Ping e Traceroute para cada peer
- ✅ Sistema de plugins
- ✅ API REST completa

## Gerenciar serviços

```bash
cd /opt/easy-vpn

docker compose ps          # Ver status
docker compose logs -f     # Ver logs em tempo real
docker compose restart     # Reiniciar tudo
docker compose down        # Parar tudo
docker compose pull && docker compose up -d  # Atualizar
```

## Backup

```bash
cd /opt/easy-vpn
docker compose down
tar -czvf backup-vpn.tar.gz data/ .env
docker compose up -d
```

## Estrutura

```
/opt/easy-vpn/
├── .env                    # Variáveis (gerado pelo script)
├── docker-compose.yml
└── data/
    └── traefik/
        ├── traefik.yml     # Config do Traefik
        └── acme.json       # Certificados SSL
```
