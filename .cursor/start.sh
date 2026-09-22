#!/usr/bin/env bash
#
# Per-boot reconciliation for the PervokaAchievement Cloud Agent environment.
# Starts PostgreSQL and re-establishes the plugin bind mount (bind mounts do
# not survive a reboot / prebuilt-environment restore). Must be idempotent and
# return promptly; the Redmine server itself runs in a terminal.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REDMINE_DIR="$HOME/workspace/redmine"
PLUGIN_MOUNT="$REDMINE_DIR/plugins/pervoka_achievement"

echo "==> Starting PostgreSQL"
sudo pg_ctlcluster "$(ls /etc/postgresql)" main start 2>/dev/null || sudo service postgresql start || true
for _ in $(seq 1 30); do sudo -u postgres pg_isready >/dev/null 2>&1 && break; sleep 1; done

echo "==> Ensuring plugin bind mount"
mkdir -p "$PLUGIN_MOUNT"
if ! mountpoint -q "$PLUGIN_MOUNT"; then
  sudo mount --bind "$REPO_ROOT" "$PLUGIN_MOUNT"
fi

echo "==> Start reconciliation complete"
