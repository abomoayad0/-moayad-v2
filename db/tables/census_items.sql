-- v2.census_items
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 b5aad9b64c6a59a94edda321da4e5893

CREATE TABLE v2.census_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    polarity text NOT NULL,
    icon text,
    text_ar text NOT NULL,
    hint_ar text,
    ord smallint DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    based_on uuid,
    CONSTRAINT census_items_pkey PRIMARY KEY (id),
    CONSTRAINT census_items_polarity_check CHECK ((polarity = ANY (ARRAY['negative'::text, 'positive'::text])))
);
ALTER TABLE v2.census_items ENABLE ROW LEVEL SECURITY;
