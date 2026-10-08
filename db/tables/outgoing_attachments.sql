-- v2.outgoing_attachments
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 0bb3c78eb2328431e83388302d44f14f

CREATE TABLE v2.outgoing_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mail_id uuid NOT NULL,
    kind text DEFAULT 'file'::text NOT NULL,
    name_ar text,
    file_ref text,
    url text,
    barcode_val text,
    form_entry uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT outgoing_attachments_pkey PRIMARY KEY (id),
    CONSTRAINT outgoing_attachments_kind_check CHECK ((kind = ANY (ARRAY['file'::text, 'link'::text, 'barcode'::text, 'form'::text])))
);
ALTER TABLE v2.outgoing_attachments ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.outgoing_attachments IS 'مرفقاتُ الصادر — ملفٌّ أو رابطٌ أو باركودٌ أو نموذجٌ رسميٌّ خرج مع الخطاب';
