-- v2.card_values
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 ad7f6df96c8ad2fae8608b0eba4bd81e

CREATE TABLE v2.card_values (
    card_code text NOT NULL,
    door_key text NOT NULL,
    value_text text,
    presence text DEFAULT 'filled'::text NOT NULL,
    CONSTRAINT card_values_pkey PRIMARY KEY (card_code, door_key),
    CONSTRAINT card_values_check CHECK (((presence = 'filled'::text) = ((value_text IS NOT NULL) AND (length(btrim(value_text)) > 0)))),
    CONSTRAINT card_values_presence_check CHECK ((presence = ANY (ARRAY['filled'::text, 'empty'::text, 'stated_none'::text])))
);
ALTER TABLE v2.card_values ENABLE ROW LEVEL SECURITY;
