#!/bin/sh
set -eu

nodes="${1:-/sys/class/kfd/kfd/topology/nodes}"
if ! result="$(awk '
  $1 == "gfx_target_version" && $2 != "0" {
    count++
    if ($2 != "110500") other++
  }
  END { if (count > 0 && other == 0) print "-f docker-compose.strata.gfx1150.yml" }
' "$nodes"/*/properties 2>/dev/null)"; then
  echo "Warning: KFD GPU topology unavailable; gfx1150 Strata overlay not enabled." >&2
  exit 0
fi
if [ -n "$result" ]; then
  printf '%s\n' "$result"
fi
