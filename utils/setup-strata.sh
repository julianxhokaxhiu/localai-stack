#!/bin/sh
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
destination="$root/.strata"
if [ -e "$destination" ]; then
  echo "$destination already exists; move it aside before preparing the bundle again." >&2
  exit 1
fi

staging="$(mktemp -d "$root/.strata.XXXXXXXX")"
trap 'rm -rf -- "$staging"' EXIT

curl -fL --retry 3 \
  https://github.com/julianxhokaxhiu/StrataCI/releases/download/v0.2.23/strata-engine-0.1.70-linux-x86_64-hip-gfx1150.tar.gz \
  -o "$staging/engine.tar.gz"
curl -fL --retry 3 \
  https://github.com/Niko1221/Strata/releases/download/v0.2.23/strata-control-0.1.70-linux-x86_64.tar.gz \
  -o "$staging/control.tar.gz"
echo "6897e69fb5194d55932004aa7e505b08dab3b79d25ae71b901cfe96ae84ad91c  $staging/engine.tar.gz" | sha256sum -c -
echo "f38d85bd5bd19393808e2bd0c7867e34c4fed968065371d77f37c11c451eeb6a  $staging/control.tar.gz" | sha256sum -c -

mkdir "$staging/engine" "$staging/control"
tar -xzf "$staging/engine.tar.gz" -C "$staging/engine" --no-same-owner
tar -xzf "$staging/control.tar.gz" -C "$staging/control" --no-same-owner
test -x "$staging/engine/strata"
test -x "$staging/control/python/bin/python3"
printf 'v0.2.23\n' > "$staging/version.txt"
rm "$staging/engine.tar.gz" "$staging/control.tar.gz"

image="$(docker compose -f "$root/docker-compose.common.yml" config --images)"
docker run --rm --user 0:0 --entrypoint chown \
  --mount "type=bind,src=$staging/control,dst=/control" \
  "$image" -R 10001:10001 /control
chmod 755 "$staging"
mv "$staging" "$destination"
trap - EXIT
echo "Prepared $destination"
