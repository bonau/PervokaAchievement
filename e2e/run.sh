#!/bin/bash
set -e

cd "$(dirname "$0")"

COMPOSE="podman-compose"
if ! command -v podman-compose &>/dev/null; then
  COMPOSE="docker-compose"
fi

cleanup() {
  echo ""
  echo "Extracting screenshots from test container..."
  mkdir -p screenshots
  podman cp e2e_test_1:/app/screenshots/. ./screenshots/ 2>/dev/null || true

  echo "Cleaning up containers..."
  $COMPOSE down 2>/dev/null || true
}
trap cleanup EXIT

echo "=== PervokaAchievement E2E Tests ==="
echo "Using: $COMPOSE"
echo ""
echo "Building images and starting services..."
echo "  - PostgreSQL 15"
echo "  - Redmine 6.1 + PervokaAchievement plugin"
echo "  - Selenium Chrome (browser)"
echo "  - Test runner (Capybara + RSpec)"
echo ""

$COMPOSE build
$COMPOSE up --abort-on-container-exit --exit-code-from test
TEST_EXIT=$?

echo ""
echo "=== Screenshots ==="
if ls screenshots/*.png 1>/dev/null 2>&1; then
  ls -lh screenshots/*.png
else
  echo "No screenshots found."
fi

exit $TEST_EXIT
