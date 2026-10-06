-- v2.session_role
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 bab8e8afa3c81435674f03b8c633b4e8

CREATE TABLE v2.session_role (
    user_id uuid NOT NULL,
    role_key text NOT NULL,
    school_id uuid,
    chosen_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT session_role_pkey PRIMARY KEY (user_id)
);
ALTER TABLE v2.session_role ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.session_role IS 'الصفة التي يعمل بها المستخدم الآن. تُختار من صفاته (وظيفته في الملاك + تكاليفه النافذة)، وتحدّ ما يفعله ولو كانت صلاحيته كاملة — فالوكيل الذي اختار صفة المعلّم لا يُقفل اليوم.';
