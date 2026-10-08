-- v2.class_moves
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 e563943440abbbfc5fca8cc7014a4ce7

CREATE TABLE v2.class_moves (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    student_id uuid NOT NULL,
    record_id uuid,
    task_id uuid,
    grade smallint NOT NULL,
    from_section text NOT NULL,
    to_section text NOT NULL,
    meeting_item uuid,
    reason_ar text NOT NULL,
    moved_at timestamp with time zone DEFAULT now() NOT NULL,
    moved_by uuid,
    returned_at timestamp with time zone,
    returned_by uuid,
    return_reason_ar text,
    return_item uuid,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT class_moves_pkey PRIMARY KEY (id),
    CONSTRAINT class_moves_check CHECK ((from_section <> to_section)),
    CONSTRAINT class_moves_check1 CHECK (((returned_at IS NULL) OR (btrim(COALESCE(return_reason_ar, ''::text)) <> ''::text))),
    CONSTRAINT class_moves_reason_ar_check CHECK ((btrim(reason_ar) <> ''::text))
);
CREATE INDEX class_moves_student_idx ON v2.class_moves USING btree (student_id);
ALTER TABLE v2.class_moves ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.class_moves IS 'نقلُ الطالب بين الفصول بقرار لجنة التوجيه — ويبقى النقلُ والرجوعُ في سجلّه (قرار مفرح أ١)';
