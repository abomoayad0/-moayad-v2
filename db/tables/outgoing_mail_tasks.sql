-- v2.outgoing_mail_tasks
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 12694de148f839e4133cbb937e9c29c3

CREATE TABLE v2.outgoing_mail_tasks (
    mail_id uuid NOT NULL,
    task_id uuid NOT NULL,
    on_event text DEFAULT 'sent'::text NOT NULL,
    CONSTRAINT outgoing_mail_tasks_pkey PRIMARY KEY (mail_id, task_id),
    CONSTRAINT outgoing_mail_tasks_on_event_check CHECK ((on_event = ANY (ARRAY['sent'::text, 'replied'::text])))
);
ALTER TABLE v2.outgoing_mail_tasks ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.outgoing_mail_tasks IS 'مُستبدَل بـ v2.outgoing_links — ولا بابَ يقرؤه الآن · يبقى حتى يأذن مفرح بحذفه';
COMMENT ON COLUMN v2.outgoing_mail_tasks.on_event IS 'sent: يُقفل البندُ بخروج الخطاب — وهو ما ترفعه المدرسة · replied: لا يُقفل إلّا بجواب الجهة — وهو ما يصدر من إدارة التعليم';
