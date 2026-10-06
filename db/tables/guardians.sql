-- v2.guardians
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 818e697a5e5b8a0d3a0710b3e90d5445

CREATE TABLE v2.guardians (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    full_name text NOT NULL,
    national_id text,
    phone text,
    relation text,
    is_primary boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    workplace_ar text,
    work_phone text,
    home_phone text,
    other_phone text,
    user_id uuid,
    portal_active boolean DEFAULT false NOT NULL,
    CONSTRAINT guardians_pkey PRIMARY KEY (id),
    CONSTRAINT guardians_full_name_check CHECK ((btrim(full_name) <> ''::text)),
    CONSTRAINT guardians_national_id_check CHECK (((national_id IS NULL) OR (national_id ~ '^[0-9]{10}$'::text)))
);
CREATE UNIQUE INDEX g_user_idx ON v2.guardians USING btree (user_id) WHERE (user_id IS NOT NULL);
CREATE INDEX guardian_student_idx ON v2.guardians USING btree (student_id);
ALTER TABLE v2.guardians ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.guardians IS 'ولي الأمر: اسمه وهويته وجواله. جوال ولي الأمر هو معرّف دخوله.';
COMMENT ON COLUMN v2.guardians.workplace_ar IS 'نموذج الالتزام المدرسي CONDUCT-1447-OFF ص57 يطلب من ولي الأمر: العمل · هاتف العمل · هاتف المنزل · رقم الجوال · رقم آخر — ويتحمّل مسؤولية صحتها.';
COMMENT ON COLUMN v2.guardians.user_id IS 'حساب ولي الأمر في البوابة. يُربط بالجوال أو بدعوة، ولا يُنشأ تلقائيًّا.';
