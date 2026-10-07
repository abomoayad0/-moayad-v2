-- v2.message_templates
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 5d696b78f31955904212298d803bfc2c

CREATE TABLE v2.message_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    key text NOT NULL,
    step_no smallint,
    body_ar text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT message_templates_pkey PRIMARY KEY (id),
    CONSTRAINT message_templates_school_id_key_step_no_key UNIQUE (school_id, key, step_no)
);
ALTER TABLE v2.message_templates ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.message_templates IS 'قوالبُ الرسائل لوليّ الأمر — النصُّ المعتمدُ من مفرح ٦/١٠/٢٠٢٦. المتغيّرات: {المدرسة} {الطالب} {الفصل} {السلوك} {الرصدة} {الأثر} {الموقّع}';
