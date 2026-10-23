-- Bench database settings, applied by bin/setup.sh --db once the db container is healthy.
-- The production dump carries HTTPS-only settings; on the bench everything is plain http.
UPDATE evo_settings      SET set_value = '0' WHERE set_name = 'require_ssl';
UPDATE evo_coll_settings SET cset_value = 'allow_both' WHERE cset_name = 'http_protocol';
SELECT set_name, set_value FROM evo_settings WHERE set_name = 'require_ssl';
SELECT cset_coll_ID, cset_value FROM evo_coll_settings WHERE cset_name = 'http_protocol';
