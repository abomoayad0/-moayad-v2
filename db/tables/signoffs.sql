-- v2.signoffs
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1f24278a67187e48c1959a5756d8867f

CREATE TABLE v2.signoffs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    subject_kind text NOT NULL,
    subject_id uuid NOT NULL,
    person_id uuid NOT NULL,
    signature_id uuid NOT NULL,
    stamp_id uuid,
    post_key text,
    signed_at timestamp with time zone DEFAULT now() NOT NULL,
    note text,
    CONSTRAINT signoffs_pkey PRIMARY KEY (id)
);
ALTER TABLE v2.signoffs ENABLE ROW LEVEL SECURITY;
