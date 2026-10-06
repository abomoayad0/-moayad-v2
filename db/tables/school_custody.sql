-- v2.school_custody
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 5134859255eb5dc37b0d7e8042b089d1

CREATE TABLE v2.school_custody (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    item_ar text NOT NULL,
    qty numeric DEFAULT 1 NOT NULL,
    unit_ar text,
    need_ref text,
    received_on date,
    received_by uuid,
    holder_role text,
    location_ar text,
    status text DEFAULT 'in_custody'::text NOT NULL,
    status_note text,
    inventory_notified boolean DEFAULT false NOT NULL,
    notified_on date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT school_custody_pkey PRIMARY KEY (id),
    CONSTRAINT cust_status_note CHECK (((status = 'in_custody'::text) OR (btrim(COALESCE(status_note, ''::text)) <> ''::text))),
    CONSTRAINT school_custody_item_ar_check CHECK ((btrim(item_ar) <> ''::text)),
    CONSTRAINT school_custody_qty_check CHECK ((qty > (0)::numeric)),
    CONSTRAINT school_custody_status_check CHECK ((status = ANY (ARRAY['in_custody'::text, 'returned'::text, 'damaged'::text, 'lost'::text, 'transferred'::text])))
);
CREATE INDEX sc_school_idx ON v2.school_custody USING btree (school_id);
ALTER TABLE v2.school_custody ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.school_custody IS 'العهد على المدرسة. س-17-ا1 الخطوة 12 (ص371): «تسجيل الاحتياج كعهدة على المدرسة» — يسجّل النظام آلياً الاحتياجات العينية التي وُفّرت كعهدة، ويُشعر مراقبة المخزون بإدارة التعليم.';
