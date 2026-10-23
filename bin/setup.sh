#!/usr/bin/env bash
# Prepare ./src from the git checkout plus ./overlay (your own conf/, media/, skins/, plugins/).
# Idempotent. `bin/setup.sh --db` (after `docker compose up -d`) applies bin/db-settings.sql. Nothing from overlay is ever added to git: paths are listed in .git/info/exclude.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -d src/.git ] || { echo "src/ is not a git checkout (git clone --branch 7.2.5 https://github.com/b2evolution/b2evolution.git src)"; exit 1; }
[ -d overlay ]  || { echo "overlay/ missing"; exit 1; }

if [ "${1:-}" = "--db" ]; then
  # Run AFTER `docker compose up -d`: switch the restored production database to plain-http bench mode.
  echo "== database: require_ssl=0, http_protocol=allow_both"
  docker compose exec -T db mariadb -ub2evo -pbench b2evolution < bin/db-settings.sql
  exit 0
fi

echo "== conf"
[ -f overlay/conf/_basic_config.php ] && cp -a overlay/conf/_basic_config.php src/conf/
cp -a conf/_config_TEST.php    src/conf/_config_TEST.php
cp -a conf/_overrides_TEST.php src/conf/_overrides_TEST.php
# a production _basic_config.php is often 0600 root: Apache runs as www-data (uid 33) in the container
chmod a+r src/conf/*.php

echo "== media (rsync, overlay wins)"
mkdir -p src/media
rsync -a overlay/media/ src/media/

echo "== skins / plugins: only what the checkout does not already have"
for d in skins plugins; do
  [ -d "overlay/$d" ] || continue
  for p in overlay/$d/*/; do
    n=$(basename "$p")
    if [ -d "src/$d/$n" ]; then
      if ! diff -rq "src/$d/$n" "$p" >/dev/null 2>&1; then
        echo "   $d/$n : exists upstream AND differs in overlay -> kept upstream, diff saved to log/overlay-diff-$d-$n.txt"
        diff -ru "src/$d/$n" "$p" > "log/overlay-diff-$d-$n.txt" || true
      fi
    else
      echo "   + $d/$n"
      cp -a "$p" "src/$d/$n"
    fi
  done
done

echo "== git excludes"
{
  echo '/conf/_basic_config.php'
  echo '/conf/_config_TEST.php'
  echo '/conf/_overrides_TEST.php'
  echo '/media/'
  for d in skins plugins; do
    for p in overlay/$d/*/; do n=$(basename "$p"); [ -d "src/$d/$n" ] && ! git -C src ls-files --error-unmatch "$d/$n" >/dev/null 2>&1 && echo "/$d/$n/"; done
  done
  echo '/_cache/'
  echo '/_logs/'
} | sort -u > src/.git/info/exclude

echo "== permissions for www-data (uid 33) on writable dirs"
mkdir -p log
chmod -R a+rwX src/media src/_cache src/_logs 2>/dev/null || true
chmod 777 log   # php-error.log is created by www-data inside the container

echo "== git status (should list nothing but your patches)"
git -C src status --short | head -20
echo "done."
