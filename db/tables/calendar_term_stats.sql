-- v2.calendar_term_stats
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 463a77eb4731acbdcdd810d96bd3380b

CREATE TABLE v2.calendar_term_stats (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint NOT NULL,
    weeks_count smallint,
    study_days smallint,
    holidays_count smallint,
    holiday_days smallint,
    note text,
    CONSTRAINT calendar_term_stats_pkey PRIMARY KEY (id),
    CONSTRAINT calendar_term_stats_year_id_term_no_key UNIQUE (year_id, term_no),
    CONSTRAINT calendar_term_stats_term_no_check CHECK ((term_no = ANY (ARRAY[1, 2])))
);
ALTER TABLE v2.calendar_term_stats ENABLE ROW LEVEL SECURITY;
