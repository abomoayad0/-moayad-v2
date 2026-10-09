-- v2.outgoing_links
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 a1d061441b4a900dee0bc7b795b7ed7c

CREATE TABLE v2.outgoing_links (
    mail_id uuid NOT NULL,
    source text NOT NULL,
    source_id uuid NOT NULL,
    on_event text DEFAULT 'sent'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT outgoing_links_pkey PRIMARY KEY (mail_id, source, source_id),
    CONSTRAINT outgoing_links_on_event_check CHECK ((on_event = ANY (ARRAY['sent'::text, 'replied'::text]))),
    CONSTRAINT outgoing_links_source_check CHECK ((source = ANY (ARRAY['behavior'::text, 'absence'::text, 'mail'::text])))
);
CREATE INDEX idx_outgoing_links_source ON v2.outgoing_links USING btree (source, source_id);
ALTER TABLE v2.outgoing_links ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.outgoing_links IS 'ما يُقفله الخطابُ الصادرُ من بنود النظام — من أيّ سلّمٍ كان · بديلُ outgoing_mail_tasks الذي كان مشدودًا إلى بنود السلوك وحدَها';
COMMENT ON COLUMN v2.outgoing_links.source IS 'behavior: بنود السلوك · absence: بنود المواظبة · mail: متابعاتُ الوارد';
COMMENT ON COLUMN v2.outgoing_links.on_event IS 'sent: يُقفل البندُ بخروج الخطاب — وهو ما ترفعه المدرسة · replied: لا يُقفل إلّا بجواب الجهة — وهو ما يصدر عنها';
