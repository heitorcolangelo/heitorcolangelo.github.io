#!/usr/bin/env bash
set -euo pipefail

fail=0
while IFS= read -r -d '' file; do
  if grep -q 'rel="canonical" href="[^"]*/"' "$file"; then
    if grep -q 'rel="canonical" href="[^"]*[^/]/"' "$file"; then
      echo "FAIL trailing slash canonical: $file"
      grep -o 'rel="canonical" href="[^"]*"' "$file" || true
      fail=1
    fi
  fi
done < <(find _site -name 'index.html' -print0)

exit "$fail"
