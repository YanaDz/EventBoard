-- Расширение для UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1) Источники информации (платформы/ресурсы верхнего уровня)
CREATE TABLE info_source (
                             id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                             code          TEXT NOT NULL UNIQUE,                       -- напр. 'telegram', 'instagram'
                             name          TEXT NOT NULL,                              -- читаемое имя
                             is_active     BOOLEAN NOT NULL DEFAULT TRUE,
                             created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                             updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                             deleted_at    TIMESTAMPTZ
);

CREATE INDEX ON info_source (code);

-- 2) Учётные данные/авторизации
CREATE TABLE auth_account (
                              id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                              info_source_id   UUID NOT NULL REFERENCES info_source(id),
                              auth_type        INTEGER NOT NULL,                        -- код типа аутентификации
                              login            TEXT,                                    -- username/email (если есть)
                              secret_encrypted TEXT,                                    -- шифротекст (не хранить открыто)
                              secret_ref       TEXT,                                    -- ссылка на секрет во внешнем хранилище
                              last_checked_at  TIMESTAMPTZ,
                              created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                              updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                              deleted_at       TIMESTAMPTZ
);

CREATE INDEX ON auth_account (info_source_id);

-- 3) Внутренние источники (конкретные каналы/страницы/чаты/сайты)
CREATE TABLE inner_source (
                              id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                              info_source_id   UUID NOT NULL REFERENCES info_source(id),
                              endpoint_type    INTEGER NOT NULL,                        -- код типа endpoint'а
                              url              TEXT NOT NULL,                           -- полная ссылка
                              handle           TEXT,                                    -- @handle/slug
                              title            TEXT,                                    -- имя канала/страницы
                              language_default INTEGER,                                 -- код языка по умолчанию
                              created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                              updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                              deleted_at       TIMESTAMPTZ,
                              UNIQUE (info_source_id, url)
);

CREATE INDEX ON inner_source (info_source_id);
CREATE INDEX ON inner_source (endpoint_type);

-- 4) События
CREATE TABLE event (
                       id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                       inner_source_id    UUID NOT NULL REFERENCES inner_source(id),
                       event_url          TEXT,                                   -- ссылка на событие/пост
                       short_description  TEXT NOT NULL,
                       full_description   TEXT,
                       tags               INTEGER[] NOT NULL DEFAULT ARRAY[]::INTEGER[],  -- массив кодов тегов
                       language           INTEGER,                                -- код языка
                       event_start_at     TIMESTAMPTZ,                            -- дата/время начала
                       event_end_at       TIMESTAMPTZ,                            -- дата/время окончания
                       external_event_id  TEXT,                                   -- внешний id мероприятия/поста
                       content_hash       TEXT,                                   -- хэш для дедупликации
                       meta_json          JSONB NOT NULL DEFAULT '{}'::jsonb,
                       created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                       updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                       deleted_at         TIMESTAMPTZ
);

CREATE INDEX ON event (inner_source_id);
CREATE INDEX ON event USING GIN (tags);          -- GIN для быстрого поиска по массиву тегов
CREATE INDEX ON event (language);
CREATE INDEX ON event (event_start_at);
CREATE INDEX ON event (external_event_id);
CREATE INDEX event_gin_meta ON event USING GIN (meta_json);

-- Дедупликация: один и тот же контент в рамках одного inner_source
CREATE UNIQUE INDEX IF NOT EXISTS uq_event_dedup
    ON event (inner_source_id, COALESCE(external_event_id, ''), COALESCE(content_hash, ''));

-- 5) Триггер для обновления updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_info_source_updated
    BEFORE UPDATE ON info_source
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_auth_account_updated
    BEFORE UPDATE ON auth_account
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_inner_source_updated
    BEFORE UPDATE ON inner_source
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_event_updated
    BEFORE UPDATE ON event
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
