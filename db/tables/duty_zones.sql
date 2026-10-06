-- v2.duty_zones
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 068734db412232dfac981ed33be6b3f8

CREATE TABLE v2.duty_zones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    key text NOT NULL,
    label_ar text NOT NULL,
    segment text NOT NULL,
    min_staff smallint DEFAULT 2 NOT NULL,
    note text,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT duty_zones_pkey PRIMARY KEY (id),
    CONSTRAINT duty_zones_school_id_key_key UNIQUE (school_id, key),
    CONSTRAINT duty_zones_segment_check CHECK ((segment = ANY (ARRAY['assembly'::text, 'break'::text, 'prayer'::text, 'dismissal'::text, 'halls'::text, 'gate'::text, 'period'::text])))
);
ALTER TABLE v2.duty_zones ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.duty_zones IS 'مواقع الإشراف والمناوبة. ض04 في س-15-ا1: «ألا يقل عدد المناوبين عن اثنين في المناوبة الواحدة».';
