-- v2.class_sections
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 a88ff0896bd8f206542e89376f379ba8

CREATE TABLE v2.class_sections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    grade smallint NOT NULL,
    section text NOT NULL,
    room_ar text,
    homeroom_person uuid,
    capacity smallint,
    active boolean DEFAULT true NOT NULL,
    label_ar text GENERATED ALWAYS AS (((
CASE grade
    WHEN 1 THEN 'الصف الأول الابتدائي'::text
    WHEN 2 THEN 'الصف الثاني الابتدائي'::text
    WHEN 3 THEN 'الصف الثالث الابتدائي'::text
    WHEN 4 THEN 'الصف الرابع الابتدائي'::text
    WHEN 5 THEN 'الصف الخامس الابتدائي'::text
    WHEN 6 THEN 'الصف السادس الابتدائي'::text
    WHEN 7 THEN 'أول متوسط'::text
    WHEN 8 THEN 'ثاني متوسط'::text
    WHEN 9 THEN 'ثالث متوسط'::text
    WHEN 10 THEN 'أول ثانوي'::text
    WHEN 11 THEN 'ثاني ثانوي'::text
    WHEN 12 THEN 'ثالث ثانوي'::text
    ELSE NULL::text
END || ' — '::text) || section)) STORED,
    CONSTRAINT class_sections_pkey PRIMARY KEY (id),
    CONSTRAINT class_sections_school_id_year_id_grade_section_key UNIQUE (school_id, year_id, grade, section),
    CONSTRAINT class_sections_grade_check CHECK (((grade >= 1) AND (grade <= 12)))
);
ALTER TABLE v2.class_sections ENABLE ROW LEVEL SECURITY;
