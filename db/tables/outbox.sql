-- v2.outbox
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 8a80b1daafc9771828af419e2b14b59c

CREATE TABLE v2.outbox (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    delivery_id uuid,
    channel text NOT NULL,
    to_phone text,
    to_email text,
    to_name text,
    body_ar text NOT NULL,
    status text DEFAULT 'queued'::text NOT NULL,
    attempts smallint DEFAULT 0 NOT NULL,
    last_error text,
    provider_ref text,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    sent_at timestamp with time zone,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT outbox_pkey PRIMARY KEY (id),
    CONSTRAINT outbox_channel_check CHECK ((channel = ANY (ARRAY['whatsapp'::text, 'sms'::text, 'email'::text]))),
    CONSTRAINT outbox_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'sent'::text, 'delivered'::text, 'failed'::text, 'cancelled'::text])))
);
CREATE INDEX ob_q ON v2.outbox USING btree (status) WHERE (status = 'queued'::text);
ALTER TABLE v2.outbox ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.outbox IS 'طابور الإرسال الفعلي. تُجهَّز الرسالة هنا بنصّها ورقم المستقبِل، ويسحبها المرسِل الخارجي ويبلّغ بالنتيجة. فالقاعدة تجهّز ولا ترسل بنفسها.';
