DROP FUNCTION IF EXISTS set_updated_at();

DROP INDEX IF EXISTS uq_event_dedup;
DROP INDEX IF EXISTS event_gin_meta;
DROP INDEX IF EXISTS event_language_idx;
DROP INDEX IF EXISTS event_tags_idx;
DROP INDEX IF EXISTS event_inner_source_id_idx;

DROP INDEX IF EXISTS inner_source_gin_meta;
DROP INDEX IF EXISTS inner_source_endpoint_type_idx;
DROP INDEX IF EXISTS inner_source_info_source_id_idx;

DROP INDEX IF EXISTS auth_account_is_valid_idx;
DROP INDEX IF EXISTS auth_account_info_source_id_idx;

DROP INDEX IF EXISTS info_source_is_active_idx;
DROP INDEX IF EXISTS info_source_platform_idx;

DROP TABLE IF EXISTS event CASCADE;
DROP TABLE IF EXISTS inner_source CASCADE;
DROP TABLE IF EXISTS auth_account CASCADE;
DROP TABLE IF EXISTS info_source CASCADE;
