-- v2.committee_school_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 86882bb79db76bb9500c22260d520ab9

CREATE TABLE v2.committee_school_rules (
    school_id uuid NOT NULL,
    committee_key text NOT NULL,
    seat_role text DEFAULT ''::text NOT NULL,
    quorum_min smallint,
    seat_count smallint,
    reason_ar text NOT NULL,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    allow_remote boolean,
    tie_rule text,
    CONSTRAINT committee_school_rules_pkey PRIMARY KEY (school_id, committee_key, seat_role),
    CONSTRAINT committee_school_rules_tie_rule_check CHECK ((tie_rule = ANY (ARRAY['رئيس'::text, 'تأجيل'::text])))
);
ALTER TABLE v2.committee_school_rules ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.committee_school_rules IS 'اجتهادُ المدرسة في اللجان — النصابُ وسعةُ المقعد المنتخَب، لكلّ مدرسةٍ على حدة. لا نصَّ لهما في الدليل.';
