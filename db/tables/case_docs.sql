-- v2.case_docs
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 7bab35fb5291fe29944e3aae4a9ebf99

CREATE TABLE v2.case_docs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    record_id uuid NOT NULL,
    task_id uuid,
    doc_type text NOT NULL,
    form_ref text NOT NULL,
    is_secret boolean DEFAULT false NOT NULL,
    body jsonb DEFAULT '{}'::jsonb NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    issued_at timestamp with time zone,
    issued_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    source text,
    source_id uuid,
    CONSTRAINT case_docs_pkey PRIMARY KEY (id),
    CONSTRAINT case_docs_doc_type_check CHECK ((doc_type = ANY (ARRAY['summons'::text, 'pledge'::text, 'guardian_notice'::text, 'counselor_referral'::text, 'behavior_plan'::text, 'written_warning'::text, 'seizure_minutes'::text, 'committee_minutes'::text, 'incident_minutes'::text, 'compensation_sheet'::text]))),
    CONSTRAINT case_docs_source_check CHECK ((source = ANY (ARRAY['behavior'::text, 'absence'::text, 'none'::text]))),
    CONSTRAINT case_docs_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'issued'::text, 'signed'::text, 'closed'::text, 'void'::text])))
);
CREATE INDEX case_docs_source_idx ON v2.case_docs USING btree (source, source_id);
CREATE INDEX cd_rec_idx ON v2.case_docs USING btree (record_id);
ALTER TABLE v2.case_docs ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.case_docs.source IS 'جنسُ البند: behavior · absence · none — وسلّمُ المواظبة يُحيل إلى الموجّه أيضًا';
