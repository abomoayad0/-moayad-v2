-- v2.name_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6d9d784b51878a9e84afb118201bcbd5

CREATE TABLE v2.name_rules (
    key text NOT NULL,
    label_ar text NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    value_num integer,
    value_text text,
    note text,
    ord smallint DEFAULT 0 NOT NULL,
    CONSTRAINT name_rules_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.name_rules ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.name_rules IS 'قواعد صياغة اسم الطالب المعروض. الاسم الأصلي من نور يبقى في full_name ولا يُمسّ؛ والمعروض يُحسب من هذه القواعد.';
