-- v2.study_plans
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1c7ed00590cc1d6b10045740c80572ce

CREATE TABLE v2.study_plans (
    id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    edition text NOT NULL,
    stage text NOT NULL,
    track text NOT NULL,
    grade smallint NOT NULL,
    subject_ar text NOT NULL,
    periods_year smallint NOT NULL,
    is_max boolean DEFAULT true NOT NULL,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT study_plans_pkey PRIMARY KEY (id),
    CONSTRAINT study_plans_edition_stage_track_grade_subject_ar_key UNIQUE (edition, stage, track, grade, subject_ar)
);
ALTER TABLE v2.study_plans ENABLE ROW LEVEL SECURITY;
