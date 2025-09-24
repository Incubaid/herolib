#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Must be run as root"
  exit 1
fi

# --- ask for username ---
read -rp "Enter username to create: " NEWUSER

# --- ask for SSH public key ---
read -rp "Enter SSH public key (or path to pubkey file): " PUBKEYINPUT
if [ -f "$PUBKEYINPUT" ]; then
  PUBKEY="$(cat "$PUBKEYINPUT")"
else
  PUBKEY="$PUBKEYINPUT"
fi

# --- ensure user exists ---
if id "$NEWUSER" >/dev/null 2>&1; then
  echo "✅ User $NEWUSER already exists"
else
  echo "➕ Creating user $NEWUSER"
  useradd -m -s /bin/bash "$NEWUSER"
fi

USERHOME=$(eval echo "~$NEWUSER")

# --- setup SSH authorized_keys ---
mkdir -p "$USERHOME/.ssh"
chmod 700 "$USERHOME/.ssh"
echo "$PUBKEY" > "$USERHOME/.ssh/authorized_keys"
chmod 600 "$USERHOME/.ssh/authorized_keys"
chown -R "$NEWUSER":"$NEWUSER" "$USERHOME/.ssh"
echo "✅ SSH key installed for $NEWUSER"

# --- ensure ourworld group exists ---
if getent group ourworld >/dev/null 2>&1; then
  echo "✅ Group 'ourworld' exists"
else
  echo "➕ Creating group 'ourworld'"
  groupadd ourworld
fi

# --- add user to group ---
if id -nG "$NEWUSER" | grep -qw ourworld; then
  echo "✅ $NEWUSER already in 'ourworld'"
else
  usermod -aG ourworld "$NEWUSER"
  echo "✅ Added $NEWUSER to 'ourworld' group"
fi

# --- setup /code ---
mkdir -p /code
chown root:ourworld /code
chmod 2775 /code   # rwx for user+group, SGID bit so new files inherit group
echo "✅ /code prepared (group=ourworld, rwx for group, SGID bit set)"

echo "🎉 Setup complete for user $NEWUSER"