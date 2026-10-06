-- v2.absence_excuse_claims
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 58311da2903ca1d29443616582f110a2

CREATE TABLE v2.absence_excuse_claims (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    student_id uuid NOT NULL,
    from_date date NOT NULL,
    to_date date NOT NULL,
    excuse_item smallint,
    reason_text text,
    submitted_by text NOT NULL,
    submitted_on date DEFAULT CURRENT_DATE NOT NULL,
    proof_ref text,
    window_days smallint,
    decision text DEFAULT 'pending'::text NOT NULL,
    decided_by uuid,
    decided_at timestamp with time zone,
    decision_note text,
    principal_extension boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    school_id uuid NOT NULL,
    channel text DEFAULT 'in_person'::text NOT NULL,
    attachment_ref text,
    attachment_name text,
    limit3_on date,
    limit10_on date,
    working_days_used smallint,
    event_id uuid,
    window_verdict text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT absence_excuse_claims_pkey PRIMARY KEY (id),
    CONSTRAINT absence_excuse_claims_channel_check CHECK ((channel = ANY (ARRAY['guardian_portal'::text, 'in_person'::text, 'whatsapp'::text, 'system'::text]))),
    CONSTRAINT absence_excuse_claims_decision_check CHECK ((decision = ANY (ARRAY['pending'::text, 'accepted'::text, 'rejected'::text]))),
    CONSTRAINT absence_excuse_claims_submitted_by_check CHECK ((submitted_by = ANY (ARRAY['student'::text, 'guardian'::text]))),
    CONSTRAINT exc_dates CHECK ((to_date >= from_date)),
    CONSTRAINT exc_decision_note CHECK (((decision <> 'rejected'::text) OR (btrim(COALESCE(decision_note, ''::text)) <> ''::text))),
    CONSTRAINT exc_ext_needs_note CHECK (((NOT principal_extension) OR (btrim(COALESCE(decision_note, ''::text)) <> ''::text)))
);
CREATE INDEX exc_student_idx ON v2.absence_excuse_claims USING btree (student_id);
ALTER TABLE v2.absence_excuse_claims ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.absence_excuse_claims IS 'أعذار الغياب. م31 بند 5: يقدّمه الطالب أو ولي أمره لإدارة المدرسة مع إرفاق ما يثبت. م31 بند 6: مهلته ثلاثة أيام عمل، وتمتد إلى عشرة بمبرر، ولمدير المدرسة تمديدها إلى نهاية الفصل مع إرفاق ما يدعم القرار. وم35 بند 5: الأعذار سرّية.';
