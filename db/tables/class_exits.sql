-- v2.class_exits
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 59b2e6e73a0e7102fb63fb26015fcc5e

CREATE TABLE v2.class_exits (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint,
    student_id uuid NOT NULL,
    section_id uuid,
    on_date date DEFAULT CURRENT_DATE NOT NULL,
    period_no smallint,
    slot_id uuid,
    to_where text NOT NULL,
    to_where_ar text NOT NULL,
    note_ar text,
    out_at timestamp with time zone DEFAULT now() NOT NULL,
    out_by uuid NOT NULL,
    out_role_ar text,
    back_at timestamp with time zone,
    back_by uuid,
    back_note text,
    is_test boolean DEFAULT false NOT NULL,
    class_session uuid,
    CONSTRAINT class_exits_pkey PRIMARY KEY (id),
    CONSTRAINT class_exits_to_where_check CHECK ((to_where = ANY (ARRAY['restroom'::text, 'counselor'::text, 'deputy'::text, 'principal'::text, 'health'::text, 'admin'::text, 'activity'::text, 'other'::text])))
);
CREATE INDEX class_exits_open_idx ON v2.class_exits USING btree (school_id, on_date) WHERE (back_at IS NULL);
CREATE INDEX class_exits_student_idx ON v2.class_exits USING btree (student_id, on_date DESC);
ALTER TABLE v2.class_exits ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.class_exits IS 'خروجُ الطالب من حصّته وعودتُه — ثمانيةُ مقاصد. موضعُ الحقيقة الوحيد لهذا الفعل، ولا يُكتب في أحداث البطاقة. وهو غيرُ الاستئذان من المدرسة (student_permissions).';
COMMENT ON COLUMN v2.class_exits.class_session IS 'جلسةُ الحصّة التي خرج منها الطالب.';
