-- v2.class_sessions
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 ba02d4c7fc79f49cb35f72c67929b15c

CREATE TABLE v2.class_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint,
    on_date date DEFAULT CURRENT_DATE NOT NULL,
    period_no smallint NOT NULL,
    section_id uuid NOT NULL,
    slot_id uuid,
    person_id uuid NOT NULL,
    basis text DEFAULT 'schedule'::text NOT NULL,
    from_ar text,
    subject_ar text,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    opened_by uuid,
    late_min smallint,
    attendance_at timestamp with time zone,
    attendance_by uuid,
    lesson_item uuid,
    lesson_ar text,
    closed_at timestamp with time zone,
    closed_by uuid,
    note_ar text,
    is_test boolean DEFAULT false NOT NULL,
    auto_closed boolean DEFAULT false NOT NULL,
    CONSTRAINT class_sessions_pkey PRIMARY KEY (id),
    CONSTRAINT class_sessions_once UNIQUE (school_id, on_date, period_no, section_id),
    CONSTRAINT class_sessions_basis_check CHECK ((basis = ANY (ARRAY['schedule'::text, 'swap'::text, 'cover'::text])))
);
CREATE INDEX class_sessions_day_idx ON v2.class_sessions USING btree (school_id, on_date, period_no);
CREATE INDEX class_sessions_open_idx ON v2.class_sessions USING btree (school_id, on_date) WHERE (closed_at IS NULL);
CREATE INDEX class_sessions_person_idx ON v2.class_sessions USING btree (person_id, on_date DESC);
ALTER TABLE v2.class_sessions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.class_sessions IS 'جلسةُ الحصّة: هل فُتحت · ومن قام بها فعلًا (أصالةً أو تبديلًا أو تغطيةً) · ومتى · وهل اعتُمد حضورُها · وأيُّ درسٍ أُعطي · ومتى أُقفلت. بيتٌ يجمع ما يقع في الحصّة، ولا ينسخ محرّكًا.';
COMMENT ON COLUMN v2.class_sessions.auto_closed IS 'أُقفلت آليًّا بانقضاء نافذة الرصد — ولم يُقفلها صاحبُها. والنقصُ مكتوبٌ في note_ar.';
