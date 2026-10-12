-- v2.loyalty_ledger
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 acba1058baaf4c8edd62e2808ee842b4

CREATE TABLE v2.loyalty_ledger (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint,
    student_id uuid NOT NULL,
    kind text NOT NULL,
    source_code text,
    reward_code text,
    points smallint NOT NULL,
    reason_ar text,
    on_date date DEFAULT CURRENT_DATE NOT NULL,
    period_no smallint,
    class_session uuid,
    by_person uuid NOT NULL,
    by_role_ar text NOT NULL,
    approved_by uuid,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_reason text,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT loyalty_ledger_pkey PRIMARY KEY (id),
    CONSTRAINT loyalty_ledger_kind_check CHECK ((kind = ANY (ARRAY['earn'::text, 'deduct'::text, 'spend'::text]))),
    CONSTRAINT loyalty_ledger_points_check CHECK ((points > 0))
);
CREATE INDEX ix_loyalty_ledger_school ON v2.loyalty_ledger USING btree (school_id, on_date DESC) WHERE (voided_at IS NULL);
CREATE INDEX ix_loyalty_ledger_source ON v2.loyalty_ledger USING btree (student_id, source_code, on_date) WHERE (voided_at IS NULL);
CREATE INDEX ix_loyalty_ledger_student ON v2.loyalty_ledger USING btree (student_id, on_date DESC) WHERE (voided_at IS NULL);
ALTER TABLE v2.loyalty_ledger ENABLE ROW LEVEL SECURITY;
