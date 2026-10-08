-- v2.guardian_contacts
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 b063ece10433394cf269ed2d4eada599

CREATE TABLE v2.guardian_contacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    guardian_id uuid,
    task_id uuid,
    record_id uuid,
    channel text NOT NULL,
    on_date date DEFAULT CURRENT_DATE NOT NULL,
    at_time time without time zone,
    outcome text NOT NULL,
    summary_ar text,
    guardian_say text,
    by_person uuid,
    attempt_no smallint DEFAULT 1 NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    right_number text,
    CONSTRAINT guardian_contacts_pkey PRIMARY KEY (id),
    CONSTRAINT guardian_contacts_channel_check CHECK ((channel = ANY (ARRAY['هاتف'::text, 'رسالة'::text, 'حضور'::text, 'بوّابة'::text]))),
    CONSTRAINT guardian_contacts_outcome_check CHECK ((outcome = ANY (ARRAY['ردّ وعلم'::text, 'ردّ ورفض'::text, 'لم يردّ'::text, 'الرقم مغلق'::text, 'الرقم خطأ'::text])))
);
CREATE INDEX ix_gc_student ON v2.guardian_contacts USING btree (student_id, on_date);
ALTER TABLE v2.guardian_contacts ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.guardian_contacts IS 'إثباتُ إشعار وليّ الأمر هاتفيًّا — CONDUCT-1447-OFF ص20، الإجراء الثالث. ولا يُقفل بندُ الإشعار إلا بإثباتٍ هنا';
