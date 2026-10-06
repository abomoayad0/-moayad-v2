-- v2.duty_roster
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 32b7f50b8c5fc954f1167c014d750240

CREATE TABLE v2.duty_roster (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
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
    zone_id uuid NOT NULL,
    person_id uuid NOT NULL,
    kind text DEFAULT 'duty'::text NOT NULL,
    decision_ref text,
    starts_on date DEFAULT CURRENT_DATE NOT NULL,
    ends_on date,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT duty_roster_pkey PRIMARY KEY (id),
    CONSTRAINT duty_roster_school_id_year_id_term_no_weekday_zone_id_perso_key UNIQUE (school_id, year_id, term_no, weekday, zone_id, person_id),
    CONSTRAINT duty_roster_kind_check CHECK ((kind = ANY (ARRAY['duty'::text, 'supervision'::text]))),
    CONSTRAINT duty_roster_term_no_check CHECK ((term_no = ANY (ARRAY[1, 2]))),
    CONSTRAINT duty_roster_weekday_check CHECK (((weekday >= 0) AND (weekday <= 6)))
);
CREATE INDEX dr_person_idx ON v2.duty_roster USING btree (person_id, weekday);
ALTER TABLE v2.duty_roster ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.duty_roster IS 'جدول الإشراف والمناوبة اليومي — س-15-ا1. يصدر بتوقيع مدير المدرسة (ض01)، ويراعى فيه العبء التدريسي، والأولوية للأقل نصاباً.';
