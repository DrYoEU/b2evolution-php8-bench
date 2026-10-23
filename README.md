# b2evolution 7.2.5 — PHP 8.x porting bench

A disposable Docker bench to run b2evolution 7.2.5 on PHP 8.2 → 8.5 with **your own site data**
(database dump, media, skins, plugins), so that compatibility fixes can be made as clean,
reviewable commits against the upstream tag and tested against real content.

The patch series produced with this bench lives in <https://github.com/DrYoEU/b2evolution>,
branch `php8-compat` (one commit per family of fix, no reformatting).

## Layout

    docker-compose.yml   mariadb:10.11 + php:${PHP_VERSION}-apache (Dockerfile adds gd mysqli mbstring zip intl apcu exif)
    .env                 PHP_VERSION=8.5  BENCH_PORT=8090      (copy .env.example)
    php/zz-bench.ini     error_reporting=E_ALL, log to log/php-error.log, display_errors Off, opcache Off
    conf/_config_TEST.php     db credentials + $baseurl/$assets_baseurl in http:// (included BEFORE _advanced.php)
    conf/_overrides_TEST.php  $display_errors_on_production = false      (included AFTER _advanced.php)
    bin/setup.sh         builds src/ from the checkout + overlay/, writes .git/info/exclude; --db applies bin/db-settings.sql
    src/                 git checkout of b2evolution — the tree you patch; `git -C src log` is the series
    overlay/             your site: conf/_basic_config.php, media/, extra skins/ and plugins/ (never committed)
    db/                  *.sql.gz dump(s), loaded by mariadb on first start of the db container
    log/                 php-error.log (+ overlay-diff-*.txt written by setup.sh)

## First run

    git clone --branch 7.2.5 https://github.com/b2evolution/b2evolution.git src
    cp .env.example .env
    # copy your site's conf/_basic_config.php, media/, skins/, plugins/ under overlay/
    # put a mysqldump of your site under db/  (gzip -9 ... > db/site.sql.gz)
    bin/setup.sh
    docker compose up -d --build
    bin/setup.sh --db               # require_ssl=0, http_protocol=allow_both on every collection
    tail -f log/php-error.log

Open `http://<host-ip>:8090/`. Log into the back-office with your production credentials.

## Things that bite

* **HTTPS redirect loop (301 to https://).** A production dump carries `require_ssl=1` and
  `http_protocol=always_https`; `$htsrv_url`/`$admin_url` are derived from `$baseurl` in `_advanced.php`,
  *before* `_overrides_TEST.php` is read. Hence `_config_TEST.php` (early) for `$baseurl`,
  and `bin/setup.sh --db` for the two database settings. Run `--db` again after reloading a dump.
* **Chrome remembers the 301.** Once it has seen a redirect to https for `<host-ip>:8090` it keeps
  applying it from cache even after the server is fixed. Use a private window, another browser,
  or clear site data for that origin. Firefox is not affected.
* **"headers already sent".** `_advanced.php` forces `display_errors=On` when
  `$display_errors_on_production` is true: one notice printed before a redirect and the page breaks.
  The bench sets it to false and reads the log instead.
* **Permissions.** `_basic_config.php` from production is usually `0600 root`; Apache is uid 33
  in the container. `setup.sh` does `chmod a+r src/conf/*.php` and `chmod 777 log`.
* **`php -l` lints only the first file** passed on the command line. Loop file by file:
  `find src -name '*.php' | while read f; do php -l "$f" | grep -v '^No syntax'; done`

## Working method

    tail -f log/php-error.log | grep -v libpng        # watch while you click through the site
    grep -h 'PHP Deprecated' log/php-error.log | sed 's/.*PHP Deprecated:  //; s/ in \/var.*//' | sort | uniq -c | sort -rn
    : > log/php-error.log                              # reset between two rounds (keep a copy first!)

Fix in `src/`, one `git commit` per family of deprecation (null to string functions, dynamic
properties, optional-before-required parameters, ...), never mixed with reformatting.
`PHP_VERSION=8.3 docker compose up -d --build` switches the PHP branch; `docker compose down -v`
throws the database away, the next `up` reloads the dump (then run `bin/setup.sh --db` again).

## What is NOT covered

PHP `imap` (removed from core in 8.4; two optional b2evolution features), the installer
(`/install/`), XML-RPC clients, and whatever your own skins/plugins do — lint them with the loop
above and watch the log while using them.
