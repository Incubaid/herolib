# Hetzner Examples

## Quick Start

### 1. Configure Environment Variables

Copy `hetzner_env.sh` and fill in your credentials:

```bash
export HETZNER_USER="your-robot-username"   # Hetzner Robot API username
export HETZNER_PASSWORD="your-password"     # Hetzner Robot API password
export HETZNER_SSHKEY_NAME="my-key"         # Name of SSH key registered in Hetzner
```

Each script has its own server name and whitelist ID defined at the top.

### 2. Run a Script

```bash
source hetzner_env.sh
./hetzner_kristof2.vsh
```

## SSH Keys

The `HETZNER_SSHKEY_NAME` must be the **name** of an SSH key already registered in your Hetzner Robot account.

Available keys in our Hetzner account:

- hossnys (RSA 2048)
- Jan De Landtsheer (ED25519 256)
- mahmoud (ED25519 256)
- kristof (ED25519 256)
- maxime (ED25519 256)

To add a new key, use `key_create` in your script or the Hetzner Robot web interface.

## Alternative: Using hero_secrets

You can also use the shared secrets repository:

```bash
hero git pull https://git.threefold.info/despiegk/hero_secrets
source ~/code/git.ourworld.tf/despiegk/hero_secrets/mysecrets.sh
```

## Troubleshooting

### Get Robot API credentials

Get your login credentials from: https://robot.hetzner.com/preferences/index

### Test API access

```bash
curl -u "your-username:your-password" https://robot-ws.your-server.de/server
```
