-- v2.incident_seizures
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 facee3714aea004ed18098c9276a43d5

CREATE TABLE v2.incident_seizures (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    record_id uuid NOT NULL,
    kind text NOT NULL,
    kind_other_ar text,
    description_ar text,
    ref text,
    is_legal_matter boolean DEFAULT false NOT NULL,
    destroyed boolean DEFAULT false NOT NULL,
    destroyed_by_committee boolean DEFAULT false NOT NULL,
    minutes_ref text,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT incident_seizures_pkey PRIMARY KEY (id),
    CONSTRAINT incident_seizures_kind_check CHECK ((kind = ANY (ARRAY['صور'::text, 'مقاطع فيديو'::text, 'محادثات'::text, 'أخرى'::text]))),
    CONSTRAINT seiz_destroy_by_committee CHECK (((NOT destroyed) OR destroyed_by_committee)),
    CONSTRAINT seiz_no_destroy_legal CHECK ((NOT (destroyed AND is_legal_matter))),
    CONSTRAINT seiz_other_needs_text CHECK (((kind <> 'أخرى'::text) OR (btrim(COALESCE(kind_other_ar, ''::text)) <> ''::text)))
);
ALTER TABLE v2.incident_seizures ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.incident_seizures IS 'المضبوطات — محضر ضبط واقعة ص68: نوع المشاهدة المضبوطة (صور · مقاطع فيديو · محادثات · أخرى). والإتلاف لا يقع إلا من لجنة التوجيه وفيما لم يرد فيه نص نظامي — فما كان مما ورد فيه نص نظامي لا يُتلف ويُحال إلى الجهات المختصة.';
