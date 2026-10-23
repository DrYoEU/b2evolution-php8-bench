<?php
/**
 * Bench config — copied to src/conf/_config_TEST.php by bin/setup.sh.
 *
 * conf/_config.php includes this file right after _basic_config.php and BEFORE
 * _advanced.php, which is where $htsrv_url, $admin_url, $rsc_url... are derived
 * from $baseurl. Anything that must influence those derived URLs belongs here,
 * not in _overrides_TEST.php (included last, too late for them).
 */
$db_config['host']     = 'db';
$db_config['user']     = 'b2evo';
$db_config['password'] = 'bench';
$db_config['name']     = 'b2evolution';

// Serve from whatever host the browser used (LAN IP, hostname, localhost), always in http://
$baseurl = 'http://' . ( isset( $_SERVER['HTTP_HOST'] ) ? $_SERVER['HTTP_HOST'] : 'localhost:8090' ) . '/';
$assets_baseurl = $baseurl;
