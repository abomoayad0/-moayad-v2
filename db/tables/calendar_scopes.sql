-- v2.calendar_scopes
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 cca524319c83c8fb17c907e3e78d20cf

CREATE TABLE v2.calendar_scopes (
    key text NOT NULL,
    label_ar text NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    regions_ar text[],
    note text,
    source_doc text,
    source_kind text DEFAULT 'وزاري'::text NOT NULL,
    CONSTRAINT calendar_scopes_pkey PRIMARY KEY (key),
    CONSTRAINT calendar_scopes_source_kind_check CHECK ((source_kind = ANY (ARRAY['وزاري'::text, 'إدارة تعليم'::text, 'معتمد بأمر إدارة النظام'::text, 'اجتهاد مشرف'::text, 'غير معروف'::text])))
);
ALTER TABLE v2.calendar_scopes ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.calendar_scopes.source_kind IS 'درجةُ المرجع: «وزاري» لما جاء بوثيقةٍ وزاريّة · «معتمد بأمر إدارة النظام» لما أقرّته إدارةُ النظام · «إدارة تعليم» لما صدر عن إدارة تعليم. ويُعرض في اللوحة بالجهة المعتمدة لا بأسماء مُعدّي الوثائق.';
