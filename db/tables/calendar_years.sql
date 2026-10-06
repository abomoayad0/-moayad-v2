-- v2.calendar_years
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1f528d22bb2b4cadf10f8c3589da4830

CREATE TABLE v2.calendar_years (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    scope_key text NOT NULL,
    name_h text NOT NULL,
    name_g text NOT NULL,
    terms_count smallint DEFAULT 2 NOT NULL,
    source_doc text,
    source_kind text DEFAULT 'وزاري'::text NOT NULL,
    CONSTRAINT calendar_years_pkey PRIMARY KEY (id),
    CONSTRAINT calendar_years_scope_key_name_h_key UNIQUE (scope_key, name_h),
    CONSTRAINT calendar_years_source_kind_check CHECK ((source_kind = ANY (ARRAY['وزاري'::text, 'إدارة تعليم'::text, 'اجتهاد مشرف'::text, 'غير معروف'::text]))),
    CONSTRAINT calendar_years_terms_count_check CHECK ((terms_count = 2))
);
ALTER TABLE v2.calendar_years ENABLE ROW LEVEL SECURITY;
