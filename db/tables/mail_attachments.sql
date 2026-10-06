-- v2.mail_attachments
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 063a8d46015c8809bd027ae08995e0ba

CREATE TABLE v2.mail_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mail_id uuid NOT NULL,
    kind text DEFAULT 'ملف'::text NOT NULL,
    name_ar text,
    file_ref text,
    url text,
    barcode_val text,
    extracted_by text DEFAULT 'يدوي'::text NOT NULL,
    confirmed boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mail_attachments_pkey PRIMARY KEY (id),
    CONSTRAINT mail_attachments_extracted_by_check CHECK ((extracted_by = ANY (ARRAY['يدوي'::text, 'آلي'::text]))),
    CONSTRAINT mail_attachments_kind_check CHECK ((kind = ANY (ARRAY['ملف'::text, 'صورة'::text, 'رابط'::text, 'باركود'::text])))
);
ALTER TABLE v2.mail_attachments ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.mail_attachments IS 'مرفقات الوارد وما استُخرج منه: الروابط والباركودات. 🔸 الاستخراج الآلي من البناء لا من الدليل، ولا يُعتمد حتى يُقرّه ماسك البريد (confirmed).';
