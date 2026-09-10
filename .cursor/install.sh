#!/usr/bin/env bash
#
# Cloud Agent install script for the PervokaAchievement Redmine plugin.
#
# The plugin cannot run on its own: it needs a Redmine host application.
# This script provisions a native Ruby + PostgreSQL toolchain, checks out a
# compatible Redmine into ~/workspace/redmine, mounts this repository in as a
# plugin, installs gems, and runs all migrations. It is idempotent so it can be
# re-run to refresh dependencies or used to build a prebuilt environment.
set -euo pipefail

REDMINE_VERSION="${REDMINE_VERSION:-6.1-stable}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REDMINE_DIR="$HOME/workspace/redmine"
PLUGIN_MOUNT="$REDMINE_DIR/plugins/pervoka_achievement"

export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"
export DEBIAN_FRONTEND=noninteractive

echo "==> Installing system packages"
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ruby ruby-dev build-essential git curl \
  libpq-dev postgresql postgresql-contrib \
  libyaml-dev zlib1g-dev libssl-dev pkg-config \
  imagemagick libmagickwand-dev tzdata ca-certificates

echo "==> Ensuring bundler (~> 2.5) is available in user scope"
gem list -i bundler -v '~> 2.5' >/dev/null 2>&1 || gem install bundler -v '~> 2.5' --no-document

echo "==> Starting PostgreSQL and ensuring role/databases"
sudo pg_ctlcluster "$(ls /etc/postgresql)" main start 2>/dev/null || sudo service postgresql start || true
for _ in $(seq 1 30); do sudo -u postgres pg_isready >/dev/null 2>&1 && break; sleep 1; done
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='redmine'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER redmine WITH PASSWORD 'redmine' CREATEDB SUPERUSER;"
for db in redmine redmine_test; do
  sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$db'" | grep -q 1 || \
    sudo -u postgres createdb -O redmine "$db"
done

echo "==> Checking out Redmine $REDMINE_VERSION"
if [ ! -d "$REDMINE_DIR/.git" ]; then
  mkdir -p "$(dirname "$REDMINE_DIR")"
  git clone --depth 1 -b "$REDMINE_VERSION" https://github.com/redmine/redmine.git "$REDMINE_DIR"
fi

echo "==> Mounting plugin into Redmine plugins directory"
mkdir -p "$PLUGIN_MOUNT"
if ! mountpoint -q "$PLUGIN_MOUNT"; then
  sudo mount --bind "$REPO_ROOT" "$PLUGIN_MOUNT"
fi

echo "==> Writing config/database.yml"
cat > "$REDMINE_DIR/config/database.yml" <<'YML'
production:
  adapter: postgresql
  database: redmine
  host: localhost
  username: redmine
  password: redmine
  encoding: utf8
development:
  adapter: postgresql
  database: redmine
  host: localhost
  username: redmine
  password: redmine
  encoding: utf8
test:
  adapter: postgresql
  database: redmine_test
  host: localhost
  username: redmine
  password: redmine
  encoding: utf8
YML

echo "==> Writing Gemfile.local (RSpec test dependencies)"
cat > "$REDMINE_DIR/Gemfile.local" <<'GEM'
gem 'rspec-rails', '~> 6.0', group: [:development, :test]
gem 'rspec_junit_formatter', group: [:test]
gem 'rails-controller-testing', group: [:test]
GEM

cd "$REDMINE_DIR"

echo "==> Installing Ruby gems"
bundle config set --local path 'vendor/bundle'
bundle install --jobs 4 --retry 3

echo "==> Generating secret token (once)"
[ -f config/initializers/secret_token.rb ] || bundle exec rake generate_secret_token

echo "==> Migrating databases and loading default data"
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement
if ! RAILS_ENV=production bundle exec rails runner 'exit(Tracker.any? ? 0 : 1)' >/dev/null 2>&1; then
  RAILS_ENV=production bundle exec rake redmine:load_default_data REDMINE_LANG=en
fi
RAILS_ENV=test bundle exec rake db:migrate
RAILS_ENV=test bundle exec rake redmine:plugins:migrate NAME=pervoka_achievement

echo "==> Precompiling assets for production"
RAILS_ENV=production bundle exec rake assets:precompile

echo "==> Setting a known admin password for local use (admin / adminadmin1)"
RAILS_ENV=production bundle exec rails runner '
  u = User.find_by_login("admin")
  if u
    u.password = "adminadmin1"
    u.password_confirmation = "adminadmin1"
    u.must_change_passwd = false
    u.save!
  end
' || true

echo "==> Install complete"
