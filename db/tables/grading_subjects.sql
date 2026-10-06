-- v2.grading_subjects
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 aa3097a907bedbe359984d1bb098b28f

CREATE TABLE v2.grading_subjects (
    id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    model_no smallint NOT NULL,
    subject_ar text NOT NULL,
    stages_ar text NOT NULL,
    CONSTRAINT grading_subjects_pkey PRIMARY KEY (id),
    CONSTRAINT grading_subjects_model_no_subject_ar_stages_ar_key UNIQUE (model_no, subject_ar, stages_ar)
);
ALTER TABLE v2.grading_subjects ENABLE ROW LEVEL SECURITY;
