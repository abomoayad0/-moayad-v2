-- v2.enrolments
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1b4a53cb1f2bc1fe936e9bb3aefa5402

CREATE TABLE v2.enrolments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    year_id uuid NOT NULL,
    school_id uuid NOT NULL,
    stage text NOT NULL,
    grade smallint NOT NULL,
    section text NOT NULL,
    joined_on date,
    ended_on date,
    end_reason text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT enrolments_pkey PRIMARY KEY (id),
    CONSTRAINT enrolments_student_id_year_id_key UNIQUE (student_id, year_id),
    CONSTRAINT enrol_dates CHECK (((ended_on IS NULL) OR (joined_on IS NULL) OR (ended_on >= joined_on))),
    CONSTRAINT enrol_end_pair CHECK ((((status = 'active'::text) AND (ended_on IS NULL) AND (end_reason IS NULL)) OR ((status = 'ended'::text) AND (ended_on IS NOT NULL) AND (end_reason IS NOT NULL)))),
    CONSTRAINT enrolments_end_reason_check CHECK ((end_reason = ANY (ARRAY['transferred'::text, 'graduated'::text, 'withdrawn'::text, 'deceased'::text, 'year_closed'::text, 'other'::text]))),
    CONSTRAINT enrolments_grade_check CHECK (((grade >= 1) AND (grade <= 12))),
    CONSTRAINT enrolments_section_check CHECK ((btrim(section) <> ''::text)),
    CONSTRAINT enrolments_stage_check CHECK ((stage = ANY (ARRAY['kindergarten'::text, 'primary'::text, 'intermediate'::text, 'secondary'::text]))),
    CONSTRAINT enrolments_status_check CHECK ((status = ANY (ARRAY['active'::text, 'ended'::text])))
);
CREATE INDEX enrol_school_idx ON v2.enrolments USING btree (school_id);
CREATE INDEX enrol_year_idx ON v2.enrolments USING btree (year_id);
ALTER TABLE v2.enrolments ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.enrolments IS 'قيد السنة: لكل طالب قيد واحد في كل سنة دراسية، فيه صفه وفصله وحالته. فيبقى تاريخه كاملاً عند الترفيع والتخرج.';
