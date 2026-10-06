-- v2.behavior_plan_counts
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 e36742176757e16ec4ea28a5a93e1551

CREATE TABLE v2.behavior_plan_counts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_id uuid NOT NULL,
    phase text NOT NULL,
    on_date date NOT NULL,
    window_ar text,
    tally smallint NOT NULL,
    CONSTRAINT behavior_plan_counts_pkey PRIMARY KEY (id),
    CONSTRAINT behavior_plan_counts_plan_id_phase_on_date_window_ar_key UNIQUE (plan_id, phase, on_date, window_ar),
    CONSTRAINT behavior_plan_counts_phase_check CHECK ((phase = ANY (ARRAY['baseline'::text, 'followup'::text]))),
    CONSTRAINT behavior_plan_counts_tally_check CHECK (((tally >= 0) AND (tally <= 99)))
);
ALTER TABLE v2.behavior_plan_counts ENABLE ROW LEVEL SECURITY;
