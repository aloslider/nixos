#!/usr/bin/env bash
set -euo pipefail


STATUS=$(bw status | jq -r '.status')
case "$STATUS" in
  "unauthenticated")
    echo "Unauthenticated. Setting server config..."

    read -rp "Enter vault domain: " VAULT_URL
    if [[ -z "$VAULT_URL" ]]; then
      echo "Error: url cannot be empty"
      exit 1
    fi
    bw config server "https://$VAULT_URL"

    export BW_SESSION=$(bw login --raw)
    ;;
  "locked")
    export BW_SESSION=$(bw unlock --raw)
    ;;
  "unlocked")
    echo "Vault is already unlocked"
    ;;
  *)
    echo "Unknown status: $STATUS"
    exit 1
    ;;
esac

echo "Syncing vault..."
bw sync

FILES_DIR="$HOME/nixos-deploy"
rm -rf "$FILES_DIR"
mkdir -p "$FILES_DIR"

AGE_DIR="$FILES_DIR/etc/age"
mkdir -p "$AGE_DIR"

KEY_FILE=$AGE_DIR/key.txt

echo "Writing age key..."
bw get item "age-keys" \
  | jq -r '.fields[] | select(.name == "private_key") | .value' \
  > "$KEY_FILE"

chmod 700 "$AGE_DIR"
chmod 600 "$KEY_FILE"

if [[ ! -s "$KEY_FILE" ]]; then
  echo "Failed to create age key"
  exit 1
fi

echo "Copying sops files..."
SOPS_DIR="$FILES_DIR/etc/sops"
mkdir -p "$SOPS_DIR"
cp .sops.yaml secrets.yaml "$SOPS_DIR"

echo "Copying nixos config..."
NIXOS_CFG_DIR="$FILES_DIR/etc/nixos-config"
rsync -r --exclude ".sops.yaml" --exclude "secrets.yaml" ./* "$NIXOS_CFG_DIR"

read -p "Enter IP of the target (user@ip): " TARGET
if [[ -z "$TARGET" ]]; then
  echo "Error: TARGET cannot be empty"
  exit 1
fi

nix run --extra-experimental-features "nix-command flakes" \
  github:nix-community/nixos-anywhere -- \
  --flake .#homelab \
  --extra-files "$FILES_DIR" \
  --target-host "$TARGET"
