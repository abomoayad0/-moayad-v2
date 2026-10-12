-- v2.class_work
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 3ede2fad0163c80a1efd74334c932d1b

CREATE TABLE v2.class_work (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint,
    section_id uuid NOT NULL,
    subject_ar text NOT NULL,
    kind text DEFAULT 'homework'::text NOT NULL,
    scope text DEFAULT 'class'::text NOT NULL,
    student_id uuid,
    body_ar text NOT NULL,
    page_ref text,
    assigned_on date DEFAULT CURRENT_DATE NOT NULL,
    period_no smallint,
    due_on date NOT NULL,
    shows_to_student boolean DEFAULT true NOT NULL,
    notify_guardian boolean DEFAULT false NOT NULL,
    by_person uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_reason text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT class_work_pkey PRIMARY KEY (id),
    CONSTRAINT class_work_kind_check CHECK ((kind = ANY (ARRAY['homework'::text, 'enrichment'::text, 'activity'::text, 'exam'::text]))),
    CONSTRAINT class_work_scope_check CHECK ((scope = ANY (ARRAY['class'::text, 'student'::text]))),
    CONSTRAINT class_work_scope_student CHECK (((scope = 'student'::text) = (student_id IS NOT NULL)))
);
CREATE INDEX class_work_live_idx ON v2.class_work USING btree (school_id, due_on DESC) WHERE (voided_at IS NULL);
CREATE INDEX class_work_section_idx ON v2.class_work USING btree (section_id, due_on DESC);
CREATE INDEX class_work_student_idx ON v2.class_work USING btree (student_id) WHERE (student_id IS NOT NULL);
ALTER TABLE v2.class_work ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.class_work IS 'الواجباتُ والأعمالُ الصفّيّة — مدًى (الفصلُ كلُّه · طالبٌ واحد) ونوعٌ وموعدٌ ومفتاحُ ظهورٍ للطالب. موضعُ الحقيقة الوحيد، ولا علاقةَ له بدليل السلوك.';
