-- v2.teaching_assignments
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d46b3c259b7f6d568cc6f66e8ccce310

CREATE TABLE v2.teaching_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint,
    person_id uuid NOT NULL,
    subject_ar text NOT NULL,
    grade smallint NOT NULL,
    section text NOT NULL,
    periods_n smallint NOT NULL,
    is_waiting boolean DEFAULT false NOT NULL,
    out_of_major boolean DEFAULT false NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT teaching_assignments_pkey PRIMARY KEY (id),
    CONSTRAINT teaching_assignments_school_id_year_id_term_no_subject_ar_g_key UNIQUE (school_id, year_id, term_no, subject_ar, grade, section),
    CONSTRAINT teaching_assignments_grade_check CHECK (((grade >= 1) AND (grade <= 12))),
    CONSTRAINT teaching_assignments_periods_n_check CHECK ((periods_n > 0)),
    CONSTRAINT teaching_assignments_section_check CHECK ((btrim(section) <> ''::text)),
    CONSTRAINT teaching_assignments_subject_ar_check CHECK ((btrim(subject_ar) <> ''::text)),
    CONSTRAINT teaching_assignments_term_no_check CHECK ((term_no = ANY (ARRAY[1, 2])))
);
CREATE INDEX ta_person_idx ON v2.teaching_assignments USING btree (person_id, year_id);
ALTER TABLE v2.teaching_assignments ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.teaching_assignments IS 'إسناد المواد: من يُدرّس ماذا لأي صف وفصل وبكم حصة. ويُجمع منه النصاب الفعلي ويُقابَل بالمقرر — وبه يُحسب «العدل بين المعلمين» (ض01 في س-8-ا1) و«الأولوية في المناوبة للأقل نصاباً» (ض01 في س-15-ا1).';
COMMENT ON COLUMN v2.teaching_assignments.out_of_major IS 'يُدرّس خارج تخصصه. يُوسم ولا يُمنع — ليظهر في التقارير.';
