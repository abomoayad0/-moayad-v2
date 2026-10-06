-- v2.calendar_weeks
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 b999d45d1a77652de1845a0a1b886215

CREATE TABLE v2.calendar_weeks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint NOT NULL,
    week_no smallint NOT NULL,
    h_months text,
    g_months text,
    from_h text,
    from_g date,
    to_h text,
    to_g date,
    is_exam_week boolean DEFAULT false NOT NULL,
    note text,
    CONSTRAINT calendar_weeks_pkey PRIMARY KEY (id),
    CONSTRAINT calendar_weeks_year_id_term_no_week_no_key UNIQUE (year_id, term_no, week_no),
    CONSTRAINT calendar_weeks_term_no_check CHECK ((term_no = ANY (ARRAY[1, 2])))
);
ALTER TABLE v2.calendar_weeks ENABLE ROW LEVEL SECURITY;
