-- v2.day_reversals
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 70157c243c23a64caf369d5ff5317a16

CREATE TABLE v2.day_reversals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    on_date date NOT NULL,
    kind text NOT NULL,
    reason text NOT NULL,
    by_person uuid,
    at_time timestamp with time zone DEFAULT now() NOT NULL,
    reverted jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT day_reversals_pkey PRIMARY KEY (id),
    CONSTRAINT day_reversals_kind_check CHECK ((kind = ANY (ARRAY['reopen'::text, 'excuse_accepted'::text]))),
    CONSTRAINT day_reversals_reason_check CHECK ((btrim(reason) <> ''::text))
);
ALTER TABLE v2.day_reversals ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.day_reversals IS 'نقض ما ترتّب على إقفال يوم. لا يُمحى شيء — يُنقض ويُقيَّد بسببه وفاعله ووقته.';
