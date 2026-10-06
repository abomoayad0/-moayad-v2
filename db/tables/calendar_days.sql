-- v2.calendar_days
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 3eb0cf6a801099968766023ec7939624

CREATE TABLE v2.calendar_days (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    year_id uuid NOT NULL,
    week_id uuid,
    on_g date NOT NULL,
    on_h text NOT NULL,
    weekday_ar text NOT NULL,
    day_kind text NOT NULL,
    holiday_id uuid,
    note text,
    CONSTRAINT calendar_days_pkey PRIMARY KEY (id),
    CONSTRAINT calendar_days_year_id_on_g_key UNIQUE (year_id, on_g),
    CONSTRAINT calendar_days_day_kind_check CHECK ((day_kind = ANY (ARRAY['study'::text, 'holiday'::text, 'exam'::text, 'suspended'::text, 'weekend'::text])))
);
CREATE INDEX cd_year_idx ON v2.calendar_days USING btree (year_id, on_g);
ALTER TABLE v2.calendar_days ENABLE ROW LEVEL SECURITY;
