-- v2.calendar_milestones
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 5af7fe89f57b259c7c392bed8a7b00f1

CREATE TABLE v2.calendar_milestones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    year_id uuid NOT NULL,
    ord smallint NOT NULL,
    term_no smallint,
    title_ar text NOT NULL,
    kind text NOT NULL,
    from_h text,
    from_g date,
    from_weekday text,
    to_h text,
    to_g date,
    to_weekday text,
    CONSTRAINT calendar_milestones_pkey PRIMARY KEY (id),
    CONSTRAINT calendar_milestones_year_id_ord_key UNIQUE (year_id, ord),
    CONSTRAINT calendar_milestones_kind_check CHECK ((kind = ANY (ARRAY['staff_return'::text, 'teachers_return'::text, 'year_start'::text, 'term_start'::text, 'term_end'::text, 'exam_start'::text, 'holiday_start'::text, 'holiday_end'::text, 'resume'::text, 'year_end_holiday'::text, 'next_year_start'::text]))),
    CONSTRAINT calendar_milestones_term_no_check CHECK ((term_no = ANY (ARRAY[1, 2])))
);
ALTER TABLE v2.calendar_milestones ENABLE ROW LEVEL SECURITY;
