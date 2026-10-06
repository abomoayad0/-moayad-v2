-- v2.calendar_scopes
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 c13e60d46446aacc2328aed7b0d8f974

CREATE TABLE v2.calendar_scopes (
    key text NOT NULL,
    label_ar text NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    regions_ar text[],
    note text,
    source_doc text,
    source_kind text DEFAULT 'وزاري'::text NOT NULL,
    CONSTRAINT calendar_scopes_pkey PRIMARY KEY (key),
    CONSTRAINT calendar_scopes_source_kind_check CHECK ((source_kind = ANY (ARRAY['وزاري'::text, 'إدارة تعليم'::text, 'اجتهاد مشرف'::text, 'غير معروف'::text])))
);
ALTER TABLE v2.calendar_scopes ENABLE ROW LEVEL SECURITY;
