-- v2.study_plan_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 c628e87da78e4340c871522333159438

CREATE TABLE v2.study_plan_rules (
    key text NOT NULL,
    text_ar text NOT NULL,
    value_num numeric,
    unit_ar text,
    kind text NOT NULL,
    item_no smallint,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT study_plan_rules_pkey PRIMARY KEY (key),
    CONSTRAINT study_plan_rules_kind_check CHECK ((kind = ANY (ARRAY['عام'::text, 'خاص'::text])))
);
ALTER TABLE v2.study_plan_rules ENABLE ROW LEVEL SECURITY;
