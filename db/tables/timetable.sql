-- v2.timetable
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 11baa88029743a6792ccb7e237b48bf3

CREATE TABLE v2.timetable (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint,
    weekday smallint NOT NULL,
    weekday_ar text GENERATED ALWAYS AS (
CASE weekday
    WHEN 0 THEN 'الأحد'::text
    WHEN 1 THEN 'الاثنين'::text
    WHEN 2 THEN 'الثلاثاء'::text
    WHEN 3 THEN 'الأربعاء'::text
    WHEN 4 THEN 'الخميس'::text
    WHEN 5 THEN 'الجمعة'::text
    ELSE 'السبت'::text
END) STORED,
    period_no smallint NOT NULL,
    section_id uuid,
    person_id uuid,
    subject_ar text,
    room_ar text,
    is_activity boolean DEFAULT false NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    slot_kind text DEFAULT 'teaching'::text NOT NULL,
    CONSTRAINT timetable_pkey PRIMARY KEY (id),
    CONSTRAINT timetable_school_id_year_id_term_no_weekday_period_no_secti_key UNIQUE (school_id, year_id, term_no, weekday, period_no, section_id),
    CONSTRAINT timetable_slot_kind_check CHECK ((slot_kind = ANY (ARRAY['teaching'::text, 'standby'::text, 'activity'::text]))),
    CONSTRAINT timetable_term_no_check CHECK ((term_no = ANY (ARRAY[1, 2]))),
    CONSTRAINT timetable_weekday_check CHECK (((weekday >= 0) AND (weekday <= 6)))
);
CREATE INDEX tt_person_idx ON v2.timetable USING btree (person_id, weekday, period_no);
CREATE UNIQUE INDEX tt_uniq ON v2.timetable USING btree (school_id, year_id, COALESCE((term_no)::integer, 0), weekday, period_no, section_id) WHERE (section_id IS NOT NULL);
ALTER TABLE v2.timetable ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.timetable IS 'جدول الحصص الدراسي — س-8-ا1. ض01: «العدل بين المعلمين في توزيع الحصص ومراعاة نصاب كل منهم».';
COMMENT ON COLUMN v2.timetable.slot_kind IS 'teaching إسناد أصيل · standby حصة انتظار محجوزة في الجدول الأسبوعي (ليست حصرًا لما وقع) · activity حصة نشاط.';
