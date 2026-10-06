-- v2.form_signatures
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 fc7f40e04f9d67b76744da6e427fd01b

CREATE TABLE v2.form_signatures (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    entry_id uuid NOT NULL,
    signer_ar text NOT NULL,
    person_id uuid,
    guardian_id uuid,
    student_id uuid,
    signed boolean,
    signed_at timestamp with time zone,
    refused boolean DEFAULT false NOT NULL,
    refuse_reason text,
    channel text DEFAULT 'portal'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT form_signatures_pkey PRIMARY KEY (id),
    CONSTRAINT form_signatures_channel_check CHECK ((channel = ANY (ARRAY['portal'::text, 'in_person'::text, 'paper'::text]))),
    CONSTRAINT fs_refuse CHECK (((NOT refused) OR (btrim(COALESCE(refuse_reason, ''::text)) <> ''::text)))
);
CREATE INDEX fs_entry ON v2.form_signatures USING btree (entry_id);
ALTER TABLE v2.form_signatures ENABLE ROW LEVEL SECURITY;
