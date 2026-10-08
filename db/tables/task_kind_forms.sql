-- v2.task_kind_forms
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 0c76029b911283a71214e32629390716

CREATE TABLE v2.task_kind_forms (
    kind text NOT NULL,
    form_no smallint NOT NULL,
    why_ar text,
    school_id uuid,
    CONSTRAINT task_kind_forms_pkey PRIMARY KEY (kind)
);
ALTER TABLE v2.task_kind_forms ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.task_kind_forms IS 'النموذجُ الرسميُّ الذي يُثبت كلَّ نوعِ مهمّة — مشتركٌ بأصله وللمدرسة أن تفصل';
