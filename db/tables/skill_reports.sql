-- v2.skill_reports
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 34d02e52da114cf1964636f6202223cb

CREATE TABLE v2.skill_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    year_id uuid,
    term_no smallint NOT NULL,
    round_no smallint NOT NULL,
    mastered_n integer DEFAULT 0 NOT NULL,
    unmastered_n integer DEFAULT 0 NOT NULL,
    unmeasured_n integer DEFAULT 0 NOT NULL,
    tools_ar text,
    weak boolean DEFAULT false NOT NULL,
    weak_why_ar text,
    expert_person uuid,
    expert_at timestamp with time zone,
    expert_note_ar text,
    prepared_by uuid,
    prepared_at timestamp with time zone DEFAULT now() NOT NULL,
    approved_by uuid,
    approved_at timestamp with time zone,
    approve_note text,
    notified_at timestamp with time zone,
    event_id uuid,
    state text DEFAULT 'draft'::text NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT skill_reports_pkey PRIMARY KEY (id),
    CONSTRAINT skill_reports_state_check CHECK ((state = ANY (ARRAY['draft'::text, 'with_expert'::text, 'approved'::text, 'notified'::text])))
);
CREATE UNIQUE INDEX ux_skill_reports_live ON v2.skill_reports USING btree (school_id, student_id, term_no, round_no) WHERE (voided_at IS NULL);
ALTER TABLE v2.skill_reports ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.skill_reports IS 'تقريرُ تقويم مهارات الطالب — مخرجُ س-٩-ا-١ ص٢١٨، وخطواتُه ص٢٢٠: يُعدُّه المعلّم · ويُحدَّد ذوو الضعف الأكاديميّ باستشارة المعلّم الخبير · ويراجعه ويعتمده الوكيلُ للشؤون التعليميّة · ثمّ يُرسل إشعارُ التقويم لوليّ الأمر. وround_no دورةُ الإشعار في الفصل، وسقفُها assess_notices_per_term (سياسة ٠١: مرّتان في كلّ فصل).';
