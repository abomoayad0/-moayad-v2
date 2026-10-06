-- v2.subject_plan
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 689bbaaf3288e9819cf4fdfc7361246f

CREATE TABLE v2.subject_plan (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    grade smallint NOT NULL,
    subject_ar text NOT NULL,
    slots smallint NOT NULL,
    ord smallint DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT subject_plan_pkey PRIMARY KEY (id),
    CONSTRAINT subject_plan_school_id_grade_subject_ar_key UNIQUE (school_id, grade, subject_ar)
);
ALTER TABLE v2.subject_plan ENABLE ROW LEVEL SECURITY;
