# Auto-start ssh-agent if not running
SSH_AGENT_PID_FILE="$HOME/.ssh/agent.pid"
SSH_AUTH_SOCK_FILE="$HOME/.ssh/agent.sock"

chown "$NEWUSER":"$NEWUSER" "$PROFILE_SCRIPT"
chmod 644 "$PROFILE_SCRIPT"

# --- source it on login ---
#TODO should be done in vcode
if ! grep -q ".profile_sshagent" "$USERHOME/.bashrc"; then
  echo "[ -f ~/.profile_sshagent ] && source ~/.profile_sshagent" >> "$USERHOME/.bashrc"
fi