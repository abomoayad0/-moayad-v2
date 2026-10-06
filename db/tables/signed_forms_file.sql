-- v2.signed_forms_file
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d7c1a4619728360e0df7c9a901a6bd7d

CREATE TABLE v2.signed_forms_file (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    student_id uuid NOT NULL,
    form_no smallint NOT NULL,
    signed_on date,
    student_signed boolean DEFAULT false NOT NULL,
    guardian_signed boolean DEFAULT false NOT NULL,
    principal_signed boolean DEFAULT false NOT NULL,
    scan_ref text,
    kept_by uuid,
    kept_role text DEFAULT 'وكيل شؤون الطلبة'::text NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT signed_forms_file_pkey PRIMARY KEY (id),
    CONSTRAINT signed_forms_file_student_id_year_id_form_no_key UNIQUE (student_id, year_id, form_no)
);
ALTER TABLE v2.signed_forms_file ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.signed_forms_file IS 'ملف النماذج الموقَّعة. ملحوظتا نموذج الالتزام المدرسي (ص57): «يؤخذ توقيع الطالب وولي الأمر في بداية العام الدراسي» و«تحفظ النماذج في ملف خاص لدى وكيل/وكيلة شؤون الطلبة».';
