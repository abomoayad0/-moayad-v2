-- v2.practice_scopes
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 01ea4c96f19eca811f29f095c4487696

CREATE TABLE v2.practice_scopes (
    key text NOT NULL,
    label_ar text NOT NULL,
    school_id uuid,
    ord smallint DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT practice_scopes_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.practice_scopes ENABLE ROW LEVEL SECURITY;
