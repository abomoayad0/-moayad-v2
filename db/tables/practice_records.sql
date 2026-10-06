-- v2.practice_records
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1002fa3478c9acb9bda72efa246ce13c

CREATE TABLE v2.practice_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint,
    student_id uuid NOT NULL,
    code text NOT NULL,
    on_date date DEFAULT CURRENT_DATE NOT NULL,
    period_no smallint,
    subject_ar text,
    points numeric(4,2) DEFAULT 0 NOT NULL,
    note text,
    by_person uuid,
    by_role text,
    undone_at timestamp with time zone,
    undo_reason text,
    escalated_record uuid,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT practice_records_pkey PRIMARY KEY (id),
    CONSTRAINT pr_undo CHECK (((undone_at IS NULL) OR (btrim(COALESCE(undo_reason, ''::text)) <> ''::text)))
);
CREATE INDEX pr_student_idx ON v2.practice_records USING btree (student_id, on_date);
ALTER TABLE v2.practice_records ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.practice_records.undone_at IS 'الممارسة تُلغى بسبب مكتوب ولا تُمحى — وأثرها في النقاط يُعكس.';
