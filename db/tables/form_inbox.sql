-- v2.form_inbox
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 0075ffb3a66c1adec2540b89af8a906d

CREATE TABLE v2.form_inbox (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entry_id uuid NOT NULL,
    to_kind text NOT NULL,
    guardian_id uuid,
    person_id uuid,
    student_id uuid,
    delivered_at timestamp with time zone DEFAULT now() NOT NULL,
    read_at timestamp with time zone,
    replied_at timestamp with time zone,
    reply text,
    reply_note text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT form_inbox_pkey PRIMARY KEY (id),
    CONSTRAINT form_inbox_to_kind_check CHECK ((to_kind = ANY (ARRAY['guardian'::text, 'student'::text, 'counselor'::text, 'committee'::text, 'external'::text])))
);
CREATE INDEX fi_g ON v2.form_inbox USING btree (guardian_id) WHERE (read_at IS NULL);
ALTER TABLE v2.form_inbox ENABLE ROW LEVEL SECURITY;
