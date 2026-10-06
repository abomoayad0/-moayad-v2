-- v2.period_attendance
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f1b554b3e31b879a8146ef7399212ecc

CREATE TABLE v2.period_attendance (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint NOT NULL,
    student_id uuid NOT NULL,
    on_date date NOT NULL,
    period_no smallint,
    subject_ar text,
    teacher_id uuid,
    state text NOT NULL,
    minutes_late smallint,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    segment text DEFAULT 'period'::text NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    recorded_by uuid,
    recorded_role text,
    CONSTRAINT period_attendance_pkey PRIMARY KEY (id),
    CONSTRAINT period_attendance_student_id_on_date_period_no_key UNIQUE (student_id, on_date, period_no),
    CONSTRAINT period_attendance_period_no_check CHECK (((period_no >= 1) AND (period_no <= 8))),
    CONSTRAINT period_attendance_state_check CHECK ((state = ANY (ARRAY['present'::text, 'absent'::text, 'late'::text, 'entered_with_permit'::text, 'permitted_out'::text])))
);
CREATE INDEX pa_day_idx ON v2.period_attendance USING btree (school_id, on_date);
CREATE UNIQUE INDEX pa_uniq ON v2.period_attendance USING btree (student_id, on_date, period_no);
ALTER TABLE v2.period_attendance ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.period_attendance IS 'سجل الحصة — مالكه معلّم الحصة. ومنه وحده: الهروب من الحصة والتأخر في الدخول إليها. ولا يمسّ سجل اليوم ولا المواظبة.';
COMMENT ON COLUMN v2.period_attendance.segment IS 'فترة اليوم التي وقعت فيها الواقعة: اصطفاف · حصة · فسحة · صلاة · انصراف. فيُعرف أين وقعت ولا يُحشر كل شيء في الحصص.';
