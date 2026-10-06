-- v2.duty_log
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 30413c41de453238d2ebd03dc7a35f97

CREATE TABLE v2.duty_log (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    on_date date NOT NULL,
    zone_id uuid NOT NULL,
    person_id uuid,
    state text DEFAULT 'present'::text NOT NULL,
    substitute uuid,
    note text,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT duty_log_pkey PRIMARY KEY (id),
    CONSTRAINT duty_log_school_id_on_date_zone_id_person_id_key UNIQUE (school_id, on_date, zone_id, person_id),
    CONSTRAINT duty_log_state_check CHECK ((state = ANY (ARRAY['present'::text, 'absent'::text, 'substituted'::text])))
);
ALTER TABLE v2.duty_log ENABLE ROW LEVEL SECURITY;
