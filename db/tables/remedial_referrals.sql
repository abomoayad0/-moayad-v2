-- v2.remedial_referrals
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1195a437c60dd1b45e0681edf7710c3d

CREATE TABLE v2.remedial_referrals (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    plan_id uuid,
    term_no smallint NOT NULL,
    to_whom text NOT NULL,
    reason_ar text NOT NULL,
    unmastered_min_n integer,
    case_id uuid,
    by_person uuid,
    at_ts timestamp with time zone DEFAULT now() NOT NULL,
    responded boolean,
    respond_note text,
    guardian_notified_at timestamp with time zone,
    to_support_programs boolean DEFAULT false NOT NULL,
    support_note text,
    voided_at timestamp with time zone,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT remedial_referrals_pkey PRIMARY KEY (id),
    CONSTRAINT remedial_referrals_to_whom_check CHECK ((to_whom = ANY (ARRAY['counselor'::text, 'deputy_students'::text, 'principal'::text])))
);
CREATE INDEX ix_remedial_referrals_student ON v2.remedial_referrals USING btree (school_id, student_id, term_no) WHERE (voided_at IS NULL);
ALTER TABLE v2.remedial_referrals ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.remedial_referrals IS 'إحالةُ الطالب في الخطّة العلاجيّة — خطوة ٠٤ ص٢٢٥: «إحالةُ الطالب الذي لم يتقن مهارةً أو أكثرَ من مهارات الحدّ الأدنى إلى الموجّه الطلابيّ»، وجهاتُها الثلاثُ منصوصةٌ في نماذج ص٢٢٣. وخطوة ٠٥: تحويلُ من لم يُبدِ تجاوبًا إلى البرامج المساندة **بعد إشعار وليّ الأمر** — وguardian_notified_at شرطٌ قبل to_support_programs.';
