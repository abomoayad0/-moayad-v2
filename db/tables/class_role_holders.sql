-- v2.class_role_holders
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 c9ed1e14413d460eec28168e8fcaf4b1

CREATE TABLE v2.class_role_holders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint,
    section_id uuid NOT NULL,
    subject_ar text NOT NULL,
    role_code text NOT NULL,
    role_ar text NOT NULL,
    student_id uuid NOT NULL,
    from_on date DEFAULT CURRENT_DATE NOT NULL,
    until_on date,
    by_person uuid NOT NULL,
    ended_at timestamp with time zone,
    ended_by uuid,
    end_reason text,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT class_role_holders_pkey PRIMARY KEY (id)
);
CREATE INDEX role_holders_live_idx ON v2.class_role_holders USING btree (section_id, subject_ar) WHERE (ended_at IS NULL);
CREATE INDEX role_holders_student_idx ON v2.class_role_holders USING btree (student_id) WHERE (ended_at IS NULL);
ALTER TABLE v2.class_role_holders ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.class_role_holders IS 'من يحمل الدورَ: في فصلٍ ومادّةٍ ومدّة. والدورُ في مادّة المعلّم وحدَها — فلكلِّ مادّةٍ عريفُها.';
