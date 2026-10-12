-- v2.skills
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 16ae53593d94f9cca760c3d329320dec

CREATE TABLE v2.skills (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    subject_ar text NOT NULL,
    grade smallint,
    code text,
    title_ar text NOT NULL,
    kind text NOT NULL,
    ord integer DEFAULT 0 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    source_ar text,
    note_ar text,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT skills_pkey PRIMARY KEY (id),
    CONSTRAINT skills_kind_check CHECK ((kind = ANY (ARRAY['minimum'::text, 'targeted'::text])))
);
CREATE UNIQUE INDEX ux_skills_live ON v2.skills USING btree (school_id, subject_ar, COALESCE(grade, (0)::smallint), title_ar) WHERE (voided_at IS NULL);
ALTER TABLE v2.skills ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.skills IS 'قائمةُ مهارات المدرسة — مدخلُ إجراء س-٩-ا-١ ص٢١٨: «قائمة مهارات الحدّ الأدنى لكلّ مادّة» وَ«قائمة المهارات والمعارف المستهدفة». وkind: minimum = حدٌّ أدنى · targeted = مستهدفة. تبدأ فارغةً ولا تُخترع فيها مهارةٌ لم يسمّها نصٌّ أو وثيقةُ مدرسة.';
