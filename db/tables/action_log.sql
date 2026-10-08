-- v2.action_log
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 de66ee7c0d49b945b2ed1f4fe2c3177f

CREATE TABLE v2.action_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    at timestamp with time zone DEFAULT now() NOT NULL,
    school_id uuid,
    person_id uuid,
    person_ar text,
    role_ar text,
    student_id uuid,
    action text NOT NULL,
    action_ar text,
    ref_table text,
    ref_id uuid,
    detail jsonb,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT action_log_pkey PRIMARY KEY (id)
);
CREATE INDEX ix_al_at ON v2.action_log USING btree (school_id, at DESC);
CREATE INDEX ix_al_student ON v2.action_log USING btree (student_id, at DESC);
ALTER TABLE v2.action_log ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.action_log IS 'قيدُ الأفعال الحسّاسة التي وقعت — منفصلٌ عن سجلّ الأخطاء، فيُعرف ما وقع لا ما فشل فقط. ويكتبه الجسرُ بنفسه لا الشاشة. ٨/١٠/٢٠٢٦';
