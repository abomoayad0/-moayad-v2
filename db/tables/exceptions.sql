-- v2.exceptions
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 7dbc0e745499308cf2f62813d1559752

CREATE TABLE v2.exceptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    rule_kind text NOT NULL,
    rule_ref text,
    system_says text NOT NULL,
    school_does text NOT NULL,
    reason text NOT NULL,
    decided_by uuid,
    decided_at timestamp with time zone DEFAULT now() NOT NULL,
    source_page text,
    year_id uuid NOT NULL,
    CONSTRAINT exceptions_pkey PRIMARY KEY (id),
    CONSTRAINT exceptions_reason_check CHECK ((length(btrim(reason)) > 0)),
    CONSTRAINT exceptions_rule_kind_check CHECK ((rule_kind = ANY (ARRAY['staffing'::text, 'structure'::text, 'committee'::text, 'inheritance'::text, 'other'::text])))
);
ALTER TABLE v2.exceptions ENABLE ROW LEVEL SECURITY;
