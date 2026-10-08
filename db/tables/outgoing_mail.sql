-- v2.outgoing_mail
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 af973bd02ae1143381a403c6f9e684fc

CREATE TABLE v2.outgoing_mail (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    serial_no integer,
    subject_ar text NOT NULL,
    body_ar text,
    to_entity text NOT NULL,
    kind text DEFAULT 'letter'::text NOT NULL,
    secrecy text DEFAULT 'عادي'::text NOT NULL,
    reply_to_mail uuid,
    ref_table text,
    ref_id uuid,
    prepared_by uuid,
    signed_by uuid,
    signed_at timestamp with time zone,
    issued_on_g date,
    issued_on_h text,
    status text DEFAULT 'draft'::text NOT NULL,
    sent_on date,
    sent_channel text,
    sent_ref text,
    needs_reply boolean DEFAULT false NOT NULL,
    reply_due_on date,
    reply_on date,
    reply_ref text,
    reply_note text,
    closed_at timestamp with time zone,
    close_note text,
    cancel_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT outgoing_mail_pkey PRIMARY KEY (id),
    CONSTRAINT outgoing_serial_unique UNIQUE (school_id, year_id, serial_no),
    CONSTRAINT outgoing_mail_kind_check CHECK ((kind = ANY (ARRAY['letter'::text, 'report'::text, 'decision'::text, 'referral'::text, 'circular'::text, 'reply'::text]))),
    CONSTRAINT outgoing_mail_secrecy_check CHECK ((secrecy = ANY (ARRAY['عادي'::text, 'سري'::text, 'سري للغاية'::text]))),
    CONSTRAINT outgoing_mail_sent_channel_check CHECK ((sent_channel = ANY (ARRAY['نظام رسمي'::text, 'بريد'::text, 'يد'::text, 'ورق'::text]))),
    CONSTRAINT outgoing_mail_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'signed'::text, 'sent'::text, 'replied'::text, 'closed'::text, 'cancelled'::text])))
);
CREATE INDEX idx_outgoing_ref ON v2.outgoing_mail USING btree (ref_table, ref_id);
CREATE INDEX idx_outgoing_school_status ON v2.outgoing_mail USING btree (school_id, status);
ALTER TABLE v2.outgoing_mail ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.outgoing_mail IS 'سجلُّ الصادر — كلُّ ما يخرج من المدرسة إلى جهةٍ خارجها · ورقمُ الصادر يُعطى حين يُوقَّع لا حين يُكتب';
COMMENT ON COLUMN v2.outgoing_mail.serial_no IS 'رقمُ الصادر — يُعطى عند التوقيع، ومتسلسلٌ لكلّ مدرسةٍ في سنتها';
COMMENT ON COLUMN v2.outgoing_mail.reply_to_mail IS 'إن كان الخطابُ ردًّا على واردٍ، فهذا هو الوارد';
COMMENT ON COLUMN v2.outgoing_mail.needs_reply IS 'هل يُنتظر جوابُ الجهة؟ فإن كان، لم يُقفل الخطابُ حتّى يُسجَّل الجواب';
