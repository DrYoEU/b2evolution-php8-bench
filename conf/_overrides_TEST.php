<?php
/**
 * Bench overrides — copied to src/conf/_overrides_TEST.php by bin/setup.sh.
 * Included LAST by conf/_config.php: use it to override keys of _advanced.php.
 */
// _advanced.php sets this to true and then forces display_errors=On, which breaks
// redirects with "headers already sent" as soon as one notice is emitted.
// The bench logs everything to log/php-error.log instead (php/zz-bench.ini).
$display_errors_on_production = false;
