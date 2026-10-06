-- v2.error_log
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 5fa8cc40e8980c34c75a22e886e422a7

CREATE TABLE v2.error_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid,
    person_ar text,
    role_ar text,
    school_id uuid,
    school_ar text,
    source text DEFAULT 'screen'::text NOT NULL,
    screen text,
    action text,
    fn_name text,
    params jsonb,
    sqlstate text,
    message text NOT NULL,
    detail text,
    hint text,
    context text,
    ua text,
    url text,
    kind text DEFAULT 'error'::text NOT NULL,
    seen boolean DEFAULT false NOT NULL,
    fixed boolean DEFAULT false NOT NULL,
    fix_note text,
    CONSTRAINT error_log_pkey PRIMARY KEY (id),
    CONSTRAINT error_log_kind_check CHECK ((kind = ANY (ARRAY['error'::text, 'guard'::text, 'warning'::text]))),
    CONSTRAINT error_log_source_check CHECK ((source = ANY (ARRAY['screen'::text, 'bridge'::text, 'engine'::text, 'unknown'::text])))
);
CREATE INDEX el_at_idx ON v2.error_log USING btree (at DESC);
CREATE INDEX el_unseen_idx ON v2.error_log USING btree (seen) WHERE (NOT seen);
ALTER TABLE v2.error_log ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.error_log IS 'كاشف الأخطاء. يسجّل كل خطأ يقع في جسر أو شاشة تلقائيًّا بمن وقع له وبأي صفة وفي أي شاشة، فلا يُحتاج إلى وصفه يدويًّا. ويُفرَّق فيه بين error (عطب يُصلَح) وguard (حارس عمل كما يجب فلا يُصلَح).';
