-- v2.card_doors
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 3e4d857671d38d1828499847c38b5a97

CREATE TABLE v2.card_doors (
    key text NOT NULL,
    label_ar text NOT NULL,
    ord smallint NOT NULL,
    is_required boolean DEFAULT true NOT NULL,
    is_repeating boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT card_doors_pkey PRIMARY KEY (key),
    CONSTRAINT card_doors_ord_key UNIQUE (ord)
);
ALTER TABLE v2.card_doors ENABLE ROW LEVEL SECURITY;
