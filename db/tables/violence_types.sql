-- v2.violence_types
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 b0031a1c5610e63cb3e2ab30f61f2f15

CREATE TABLE v2.violence_types (
    key text NOT NULL,
    family text NOT NULL,
    label_ar text NOT NULL,
    definition_ar text,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT violence_types_pkey PRIMARY KEY (key),
    CONSTRAINT violence_types_family_check CHECK ((family = ANY (ARRAY['عنف'::text, 'تنمر'::text])))
);
ALTER TABLE v2.violence_types ENABLE ROW LEVEL SECURITY;
