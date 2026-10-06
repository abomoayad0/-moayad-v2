-- v2.grading_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 aae148c065e6d13d3f5a98c32d3d9ce5

CREATE TABLE v2.grading_rules (
    key text NOT NULL,
    label_ar text NOT NULL,
    text_ar text NOT NULL,
    value_num numeric,
    unit_ar text,
    item_no smallint,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT grading_rules_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.grading_rules ENABLE ROW LEVEL SECURITY;
