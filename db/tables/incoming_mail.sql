-- v2.incoming_mail
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 bda896ccad4acd113485fd0e17fa11c2

CREATE TABLE v2.incoming_mail (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    serial_no integer NOT NULL,
    ref_no text,
    from_entity text NOT NULL,
    subject_ar text NOT NULL,
    body_ar text,
    received_on_g date NOT NULL,
    received_on_h text,
    doc_date_g date,
    doc_date_h text,
    secrecy text DEFAULT 'عادي'::text NOT NULL,
    received_by uuid,
    archived boolean DEFAULT false NOT NULL,
    archived_at timestamp with time zone,
    directed_by uuid,
    directed_at timestamp with time zone,
    status text DEFAULT 'new'::text NOT NULL,
    closed_at timestamp with time zone,
    close_note text,
    source text DEFAULT 'school_inbox'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT incoming_mail_pkey PRIMARY KEY (id),
    CONSTRAINT incoming_mail_school_id_year_id_serial_no_key UNIQUE (school_id, year_id, serial_no),
    CONSTRAINT incoming_mail_from_entity_check CHECK ((btrim(from_entity) <> ''::text)),
    CONSTRAINT incoming_mail_secrecy_check CHECK ((secrecy = ANY (ARRAY['عادي'::text, 'سري'::text, 'سري عاجل'::text, 'غير قابل للتداول'::text]))),
    CONSTRAINT incoming_mail_source_check CHECK ((source = ANY (ARRAY['school_inbox'::text, 'hand'::text, 'system'::text, 'other'::text]))),
    CONSTRAINT incoming_mail_status_check CHECK ((status = ANY (ARRAY['new'::text, 'directed'::text, 'in_progress'::text, 'closed'::text]))),
    CONSTRAINT incoming_mail_subject_ar_check CHECK ((btrim(subject_ar) <> ''::text)),
    CONSTRAINT mail_close_note CHECK (((status <> 'closed'::text) OR (btrim(COALESCE(close_note, ''::text)) <> ''::text)))
);
CREATE INDEX im_school_idx ON v2.incoming_mail USING btree (school_id, received_on_g);
ALTER TABLE v2.incoming_mail ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.incoming_mail IS 'سجل الوارد العام. س-15-ا3 (PROC-1446-OFF ص358–362): تسجيل بيانات المراسلات الواردة في بيان الوارد العام · أرشفة المراسلات ومرفقاتها · التوجيه بتنفيذ متطلبات الرسائل الواردة · حفظ بنود متطلبات التنفيذ للمتابعة.';
COMMENT ON COLUMN v2.incoming_mail.secrecy IS 'وسم السرّية. ض01 في س-15-ا2: «إرسال المعاملات السرية داخل ظرف مغلق ويسجل على الظرف (سري – سري عاجل – غير قابل للتداول)». والسرّي لا يُعرض إلا على من وُجّه إليه.';
