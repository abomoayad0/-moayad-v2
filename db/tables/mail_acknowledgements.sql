-- v2.mail_acknowledgements
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 07fbd9c2e5a0cf77a2f4b3e0221c4241

CREATE TABLE v2.mail_acknowledgements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mail_id uuid NOT NULL,
    item_id uuid,
    person_id uuid,
    guardian_id uuid,
    student_id uuid,
    seen_at timestamp with time zone,
    signed boolean DEFAULT false NOT NULL,
    signed_at timestamp with time zone,
    sign_kind text,
    refused boolean DEFAULT false NOT NULL,
    refuse_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mail_acknowledgements_pkey PRIMARY KEY (id),
    CONSTRAINT ack_refuse CHECK (((NOT refused) OR (btrim(COALESCE(refuse_reason, ''::text)) <> ''::text))),
    CONSTRAINT ack_signed CHECK (((NOT signed) OR (signed_at IS NOT NULL))),
    CONSTRAINT ack_who CHECK ((num_nonnulls(person_id, guardian_id, student_id) = 1)),
    CONSTRAINT mail_acknowledgements_sign_kind_check CHECK ((sign_kind = ANY (ARRAY['in_app'::text, 'on_paper'::text, 'by_deputy_witness'::text])))
);
CREATE INDEX ma_mail_idx ON v2.mail_acknowledgements USING btree (mail_id);
ALTER TABLE v2.mail_acknowledgements ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.mail_acknowledgements IS 'الإقرار بالاطلاع والتوقيع. سند: الدليل التنظيمي ORG-1442-OFF — من مهام مدير المدرسة إطلاع جميع منسوبي المدرسة على اللوائح والأنظمة والتعاميم ومناقشتها «وأخذ توقيعاتهم بذلك». ومن لم يُقرّ يظهر باسمه ولا يُطوى.';
