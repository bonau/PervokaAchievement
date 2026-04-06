#!/bin/bash
set -e

REDMINE_URL="${REDMINE_URL:-http://redmine:3000}"
SELENIUM_URL="${SELENIUM_URL:-http://chrome:4444}"
MAX_WAIT=180

echo "Waiting for Redmine at ${REDMINE_URL}..."
elapsed=0
until curl -sf "${REDMINE_URL}/login" > /dev/null 2>&1; do
  if [ $elapsed -ge $MAX_WAIT ]; then
    echo "ERROR: Redmine did not become ready within ${MAX_WAIT}s"
    exit 1
  fi
  sleep 5
  elapsed=$((elapsed + 5))
  echo "  Still waiting... (${elapsed}s)"
done
echo "Redmine is ready (${elapsed}s)"

# Wait extra time for default data to be loaded (E2E entrypoint loads it after server starts)
echo ""
echo "Waiting for Redmine default data to be loaded..."
sleep 10

echo ""
echo "Waiting for Selenium Chrome at ${SELENIUM_URL}..."
elapsed=0
until curl -sf "${SELENIUM_URL}/status" > /dev/null 2>&1; do
  if [ $elapsed -ge 60 ]; then
    echo "ERROR: Selenium did not become ready within 60s"
    exit 1
  fi
  sleep 3
  elapsed=$((elapsed + 3))
  echo "  Still waiting... (${elapsed}s)"
done
echo "Selenium Chrome is ready (${elapsed}s)"

echo ""
echo "=== Running E2E Tests ==="
echo ""
exec bundle exec rspec spec/ --format documentation --color
