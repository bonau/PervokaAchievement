#!/usr/bin/env bash
#
# Runs the Redmine host (production) with the PervokaAchievement plugin.
# Served on http://localhost:3000 — default login: admin / adminadmin1
set -euo pipefail

export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"
export RAILS_ENV=production
export RAILS_SERVE_STATIC_FILES=true

cd "$HOME/workspace/redmine"
exec bundle exec rails server -b 0.0.0.0 -p 3000
