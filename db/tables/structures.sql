-- v2.structures
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 568142f3efe20f3bc94a4761ba14aaef

CREATE TABLE v2.structures (
    code text NOT NULL,
    label_ar text NOT NULL,
    deputy_count smallint NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT structures_pkey PRIMARY KEY (code),
    CONSTRAINT structures_deputy_count_check CHECK (((deputy_count >= 0) AND (deputy_count <= 3)))
);
ALTER TABLE v2.structures ENABLE ROW LEVEL SECURITY;
