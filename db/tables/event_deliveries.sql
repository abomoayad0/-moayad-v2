-- v2.event_deliveries
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 8b4718580b0da1d3bb106d3ec4ff7162

CREATE TABLE v2.event_deliveries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    event_id uuid NOT NULL,
    channel text NOT NULL,
    to_guardian uuid,
    to_person uuid,
    to_role text,
    status text DEFAULT 'queued'::text NOT NULL,
    sent_at timestamp with time zone,
    read_at timestamp with time zone,
    fail_reason text,
    cancel_reason text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT event_deliveries_pkey PRIMARY KEY (id),
    CONSTRAINT del_cancel_reason CHECK (((status <> 'cancelled'::text) OR (btrim(COALESCE(cancel_reason, ''::text)) <> ''::text))),
    CONSTRAINT event_deliveries_channel_check CHECK ((channel = ANY (ARRAY['guardian_portal'::text, 'student_portal'::text, 'whatsapp'::text, 'staff_inbox'::text]))),
    CONSTRAINT event_deliveries_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'sent'::text, 'delivered'::text, 'read'::text, 'failed'::text, 'cancelled'::text])))
);
CREATE INDEX ed_event_idx ON v2.event_deliveries USING btree (event_id);
ALTER TABLE v2.event_deliveries ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.event_deliveries IS 'قنوات تسليم الحدث الواحد: صفحة ولي الأمر · واتساب · بريد المنسوب. الحدث واحد في القاعدة والقنوات نوافذ عليه — فلا يتولّد حدثان ولا يتقاطعان.';
COMMENT ON COLUMN v2.event_deliveries.channel IS 'قناةُ التسليم — صفحةُ وليّ الأمر · صفحةُ الطالب · واتساب · صندوقُ المنسوبين';
