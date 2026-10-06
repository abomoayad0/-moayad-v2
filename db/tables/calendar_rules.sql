-- v2.calendar_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 c6d52f444c26f5c3254509c2490aa760

CREATE TABLE v2.calendar_rules (
    key text NOT NULL,
    label_ar text NOT NULL,
    text_ar text NOT NULL,
    source_doc text,
    source_kind text DEFAULT 'وزاري'::text NOT NULL,
    CONSTRAINT calendar_rules_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.calendar_rules ENABLE ROW LEVEL SECURITY;
