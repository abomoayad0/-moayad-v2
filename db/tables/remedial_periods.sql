-- v2.remedial_periods
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 3047000bc12da00559d28aad91727d00

CREATE TABLE v2.remedial_periods (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    plan_id uuid NOT NULL,
    school_id uuid NOT NULL,
    weekday smallint NOT NULL,
    period_no smallint NOT NULL,
    section_id uuid,
    person_id uuid NOT NULL,
    from_standby boolean DEFAULT false NOT NULL,
    slot_id uuid,
    state text DEFAULT 'proposed'::text NOT NULL,
    why_ar text,
    proposed_by uuid,
    proposed_at timestamp with time zone DEFAULT now() NOT NULL,
    approved_by uuid,
    approved_at timestamp with time zone,
    cancelled_by uuid,
    cancelled_at timestamp with time zone,
    cancel_why text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT remedial_periods_pkey PRIMARY KEY (id),
    CONSTRAINT remedial_periods_state_check CHECK ((state = ANY (ARRAY['proposed'::text, 'approved'::text, 'cancelled'::text])))
);
CREATE UNIQUE INDEX ux_remedial_periods_live ON v2.remedial_periods USING btree (school_id, person_id, weekday, period_no) WHERE (state <> 'cancelled'::text);
ALTER TABLE v2.remedial_periods ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.remedial_periods IS 'قائمةُ الحصص العلاجيّة — مخرجٌ منصوصٌ في ص٢٢٣ ونموذجُه «نموذجُ الحصص العلاجيّة المقترحة». وبقرار مفرح ١٠/١٠/٢٠٢٦ «أ»: تُكتب خانةً حقيقيّةً في v2.timetable بنوعٍ remedial عند اعتماد الوكيل لا قبله، وslot_id موضعُ الخانة. وأرقامُ التحكّم خمسةٌ في مرجع الأرقام، كلُّها قرارُ مدرسة.';
