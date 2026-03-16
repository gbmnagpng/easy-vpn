# 🔒 Easy VPN

Stack de VPN completa com WGDashboard v4.3 + Traefik + SSL automático via DuckDNS.

## Serviços

| Serviço | Função |
|---|---|
| **WGDashboard v4.3** | WireGuard VPN + Interface web completa com 2FA nativo |
| **Traefik v2.11** | Proxy reverso com SSL automático via DuckDNS |

## Pré-requisitos

- Ubuntu 22.04 ou 24.04
- Subdomínio DuckDNS apontando para o IP do servidor
- Portas **80**, **443** e **51820/UDP** abertas

## Instalação

```bash
wget https://raw.githubusercontent.com/gbmnagpng/easy-vpn/main/bootstrap.sh -O bootstrap.sh && sudo bash bootstrap.sh
```

O script pergunta interativamente:
1. **Domínio DuckDNS** — ex: `meusite.duckdns.org`
2. **Token DuckDNS** — em [duckdns.org](https://www.duckdns.org)
3. **Usuário e senha** — admin do WGDashboard

## Após a instalação

Acesse: `https://wg.<seu-dominio>.duckdns.org`

## Gerenciar serviços

```bash
cd /opt/easy-vpn

docker compose ps                                    # Ver status
docker compose logs -f                               # Ver logs
docker compose restart                               # Reiniciar
docker compose down                                  # Parar
docker compose pull && docker compose up -d          # Atualizar
```

## Backup

```bash
cd /opt/easy-vpn
docker compose down
tar -czvf backup-vpn.tar.gz data/ .env docker-compose.yml
docker compose up -d
```

## Estrutura

```
/opt/easy-vpn/
├── .env                    # Variáveis (gerado pelo script)
├── docker-compose.yml
└── data/
    └── traefik/
        ├── traefik.yml
        └── acme.json
```
