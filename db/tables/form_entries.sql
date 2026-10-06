-- v2.form_entries
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d624bf3b90b4ee293ac1689d791a1f30

CREATE TABLE v2.form_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    form_no smallint NOT NULL,
    student_id uuid,
    record_id uuid,
    case_id uuid,
    task_id uuid,
    mail_id uuid,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    rows_data jsonb DEFAULT '[]'::jsonb NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    void_reason text,
    filled_by uuid,
    filled_role text,
    finalized_at timestamp with time zone,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    guardian_note text,
    CONSTRAINT form_entries_pkey PRIMARY KEY (id),
    CONSTRAINT form_entries_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'final'::text, 'void'::text])))
);
CREATE INDEX fe_student ON v2.form_entries USING btree (student_id, form_no);
CREATE INDEX fe_task ON v2.form_entries USING btree (task_id);
ALTER TABLE v2.form_entries ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.form_entries IS 'النماذج الرسمية تُملأ في الشاشة وتُحفظ هنا — لا تُطبع لتُملأ باليد. data للحقول المفردة، وrows_data لصفوف الجدول. والتوقيعات في form_signatures.';
