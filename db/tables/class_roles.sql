-- v2.class_roles
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1ff28cdd5dc5670dea3881a9e3e10e74

CREATE TABLE v2.class_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    code text NOT NULL,
    title_ar text NOT NULL,
    max_holders smallint DEFAULT 1 NOT NULL,
    ord smallint DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    note_ar text,
    CONSTRAINT class_roles_pkey PRIMARY KEY (id),
    CONSTRAINT class_roles_code_once UNIQUE (school_id, code)
);
ALTER TABLE v2.class_roles ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.class_roles IS 'قائمةُ أدوار الصفّ — تُزاد وتُحذف وتُسمّى من لوحة التحكّم، ولكلِّ دورٍ عددُ من يحمله.';
