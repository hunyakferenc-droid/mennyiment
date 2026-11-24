#!/usr/bin/env bash
# Retry only observed Maven/Gradle server throttling. Surface every build failure.
set -euo pipefail
log=$(mktemp)
trap 'rm -f "$log"' EXIT
for delay in 0 30 90 180; do
  if (( delay > 0 )); then
    echo "Dependency server throttled Gradle. Retrying in ${delay}s."
    sleep "$delay"
  fi
  if "$@" 2>&1 | tee "$log"; then
    exit 0
  else
    status=${PIPESTATUS[0]}
  fi
  if ! grep -Eq 'status code 429|HTTP[^ ]* 429|429 Too Many Requests' "$log"; then
    exit "$status"
  fi
done
exit "$status"
