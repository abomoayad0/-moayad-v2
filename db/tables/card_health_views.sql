-- v2.card_health_views
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 169faebda96a520d608cae38651e9ad5

CREATE TABLE v2.card_health_views (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    session_id uuid,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    person_id uuid NOT NULL,
    at_ts timestamp with time zone DEFAULT now() NOT NULL,
    private_ack boolean DEFAULT false NOT NULL,
    seconds_open smallint,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT card_health_views_pkey PRIMARY KEY (id)
);
ALTER TABLE v2.card_health_views ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.card_health_views IS '⛔ مكرَّرٌ لا يُستعمل — وسجلُّ الاطّلاع المعمولُ به هو v2.card_views المبنيُّ ١٢:٥٤/١١-١٠. أُبقي عليه موسومًا ولا يكتب فيه بابٌ.';
