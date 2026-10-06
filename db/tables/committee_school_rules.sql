-- v2.committee_school_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f611c0fd537de400fbe01781b6300861

CREATE TABLE v2.committee_school_rules (
    school_id uuid NOT NULL,
    committee_key text NOT NULL,
    seat_role text DEFAULT ''::text NOT NULL,
    quorum_min smallint,
    seat_count smallint,
    reason_ar text NOT NULL,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT committee_school_rules_pkey PRIMARY KEY (school_id, committee_key, seat_role)
);
ALTER TABLE v2.committee_school_rules ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.committee_school_rules IS 'اجتهادُ المدرسة في اللجان — النصابُ وسعةُ المقعد المنتخَب، لكلّ مدرسةٍ على حدة. لا نصَّ لهما في الدليل.';
