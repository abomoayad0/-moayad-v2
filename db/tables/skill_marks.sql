-- v2.skill_marks
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 38086519e176fc75a9ee3357323237ba

CREATE TABLE v2.skill_marks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint NOT NULL,
    student_id uuid NOT NULL,
    skill_id uuid NOT NULL,
    level text NOT NULL,
    on_date date NOT NULL,
    period_no smallint,
    session_id uuid,
    note_ar text,
    recorded_by uuid,
    recorded_role text,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    is_test boolean DEFAULT false NOT NULL,
    tool_key text,
    CONSTRAINT skill_marks_pkey PRIMARY KEY (id)
);
CREATE INDEX ix_skill_marks_term ON v2.skill_marks USING btree (school_id, term_no, student_id) WHERE (voided_at IS NULL);
CREATE UNIQUE INDEX ux_skill_marks_live ON v2.skill_marks USING btree (student_id, skill_id, on_date) WHERE (voided_at IS NULL);
ALTER TABLE v2.skill_marks ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.skill_marks IS 'سجلُّ متابعة مهارات الطلّاب — موضعُ الرصد المنصوصُ في س-٨-ا-٣ سياسة ٠١ ص٢٠٩ وخطوة ٠٣ ص٢١٣. والمقياسُ حالان بنصّ الدليل: متقنٌ وغيرُ متقن (ص٢٤٢ «المهارات غير المتقنة»)، وأيُّ درجةٍ ثالثةٍ اجتهادٌ يُعلَن. والتاريخُ يحفظ التتبّعَ فالسجلُّ متابعةٌ لا لقطة.';
