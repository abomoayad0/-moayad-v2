-- v2.conduct_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d75a83e071d371ce57c3795efb193ce4

CREATE TABLE v2.conduct_rules (
    key text NOT NULL,
    label_ar text NOT NULL,
    value_num numeric,
    unit_ar text,
    text_ar text NOT NULL,
    article_no smallint NOT NULL,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT conduct_rules_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.conduct_rules ENABLE ROW LEVEL SECURITY;
