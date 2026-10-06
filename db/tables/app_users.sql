-- v2.app_users
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 03294e81b899600f44bdb61a2ebaa941

CREATE TABLE v2.app_users (
    id uuid NOT NULL,
    tenant_id uuid NOT NULL,
    person_id uuid,
    role text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id uuid,
    CONSTRAINT app_users_pkey PRIMARY KEY (id),
    CONSTRAINT app_users_role_check CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'operator'::text, 'viewer'::text])))
);
ALTER TABLE v2.app_users ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.app_users.role IS 'الصلاحية الممنوحة — طبقة مستقلة عن الوظيفة في الملاك وعن التكليف. owner كل شيء · admin إدارة المدرسة · operator يعمل في حدود تكليفه · viewer اطّلاع. ولا تُشتقّ من post_key ولا من assignments.';
COMMENT ON COLUMN v2.app_users.school_id IS 'مدرسة المستخدم. فارغة = مستوى المجمّع كله (المالك والمدير العام)؛ ومحدّدة = لا يرى ولا يكتب إلا فيها. فالمساعد الإداري لمدرسة واحدة لا لمجمّع.';
