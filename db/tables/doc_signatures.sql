-- v2.doc_signatures
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1e31b9ef8857aed6af3cc537de2a85a9

CREATE TABLE v2.doc_signatures (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    doc_id uuid NOT NULL,
    signer_kind text NOT NULL,
    signer_student uuid,
    signer_person uuid,
    channel text NOT NULL,
    outcome text NOT NULL,
    signed_at timestamp with time zone DEFAULT now() NOT NULL,
    witnessed_by uuid,
    refusal_note text,
    CONSTRAINT doc_signatures_pkey PRIMARY KEY (id),
    CONSTRAINT doc_signatures_channel_check CHECK ((channel = ANY (ARRAY['in_app'::text, 'on_paper'::text, 'by_deputy_witness'::text]))),
    CONSTRAINT doc_signatures_outcome_check CHECK ((outcome = ANY (ARRAY['signed'::text, 'refused'::text, 'absent'::text]))),
    CONSTRAINT doc_signatures_signer_kind_check CHECK ((signer_kind = ANY (ARRAY['student'::text, 'guardian'::text, 'teacher'::text, 'deputy'::text, 'principal'::text, 'counselor'::text, 'committee'::text]))),
    CONSTRAINT sig_refusal_note CHECK (((outcome <> 'refused'::text) OR (btrim(COALESCE(refusal_note, ''::text)) <> ''::text))),
    CONSTRAINT sig_witness_needed CHECK (((channel <> 'by_deputy_witness'::text) OR (witnessed_by IS NOT NULL)))
);
CREATE INDEX ds_doc_idx ON v2.doc_signatures USING btree (doc_id);
ALTER TABLE v2.doc_signatures ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.doc_signatures IS 'توقيع كل طرف على المستند: في النظام من حسابه، أو على الورق، أو بشهادة الوكيل. والرفض يُسجَّل بسببه ولا يوقف بقية الإجراء.';
