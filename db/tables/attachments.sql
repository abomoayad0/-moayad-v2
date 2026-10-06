-- v2.attachments
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6f880f76909ef82809f656cbd8e67feb

CREATE TABLE v2.attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    student_id uuid,
    guardian_id uuid,
    kind text NOT NULL,
    file_name text NOT NULL,
    mime text,
    size_kb integer,
    storage_path text,
    note text,
    uploaded_by uuid,
    uploaded_role text,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT attachments_pkey PRIMARY KEY (id),
    CONSTRAINT attachments_kind_check CHECK ((kind = ANY (ARRAY['excuse'::text, 'pledge'::text, 'medical'::text, 'other'::text])))
);
ALTER TABLE v2.attachments ENABLE ROW LEVEL SECURITY;
