-- v2.attendance_ledger
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 83180132db4a09920cacbdba803ace3b

CREATE TABLE v2.attendance_ledger (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    student_id uuid NOT NULL,
    kind text NOT NULL,
    points numeric NOT NULL,
    on_date date,
    reason text NOT NULL,
    by_person uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT attendance_ledger_pkey PRIMARY KEY (id),
    CONSTRAINT attendance_ledger_kind_check CHECK ((kind = ANY (ARRAY['opening'::text, 'deduction'::text, 'restore'::text])))
);
CREATE INDEX attl_student_idx ON v2.attendance_ledger USING btree (student_id, year_id);
ALTER TABLE v2.attendance_ledger ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.attendance_ledger IS 'درجات المواظبة: 100 افتتاحية للعام الدراسي (لا للفصل، م31 بند 2: «خلال العام الدراسي»). حسم درجة عن كل يوم غياب بدون عذر، وردّها إن قُبل العذر لاحقاً.';
