-- v2.teacher_subjects
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f532f92ce50a872d73a443573b5ea7b9

CREATE TABLE v2.teacher_subjects (
    school_id uuid NOT NULL,
    person_id uuid NOT NULL,
    subject_ar text NOT NULL,
    is_main boolean DEFAULT true NOT NULL,
    CONSTRAINT teacher_subjects_pkey PRIMARY KEY (school_id, person_id, subject_ar)
);
ALTER TABLE v2.teacher_subjects ENABLE ROW LEVEL SECURITY;
