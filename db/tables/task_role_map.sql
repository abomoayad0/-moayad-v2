-- v2.task_role_map
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 9f7a7e6e492ac275956561a666cb3bd6

CREATE TABLE v2.task_role_map (
    owner_role text NOT NULL,
    role_keys text[] DEFAULT '{}'::text[] NOT NULL,
    committee_key text,
    is_external boolean DEFAULT false NOT NULL,
    needs_context text,
    note_ar text,
    source_ar text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT task_role_map_pkey PRIMARY KEY (owner_role)
);
ALTER TABLE v2.task_role_map ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.task_role_map IS 'ترجمةُ لفظ الدليل في owner_role إلى مفاتيح أدوارنا — بديلُ المطابقة الحرفيّة التي كانت تُفرّغ باب «ما ينتظرني»';
