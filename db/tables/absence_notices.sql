-- v2.absence_notices
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 9e4aa0d03949f7a4e7b60750a471184c

CREATE TABLE v2.absence_notices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    on_date date NOT NULL,
    excused boolean,
    excuse_due date,
    event_id uuid,
    by_person uuid,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT absence_notices_pkey PRIMARY KEY (id),
    CONSTRAINT absence_notices_student_id_on_date_key UNIQUE (student_id, on_date)
);
CREATE INDEX absence_notices_day_idx ON v2.absence_notices USING btree (school_id, on_date);
ALTER TABLE v2.absence_notices ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.absence_notices IS 'إخطارُ وليّ الأمر بغياب يومٍ واحد — واجبٌ يوميٌّ (م35) لا بندٌ في السلّم · والصفُّ شاهدُ أنّ المدرسةَ أدّت واجبَها في يومه';
