-- v2.staff_late_actions
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 aa710e726832d6578e367b2c2a97415d

CREATE TABLE v2.staff_late_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    person_id uuid NOT NULL,
    fiscal_year smallint NOT NULL,
    kind text NOT NULL,
    at_minutes integer NOT NULL,
    days smallint,
    why_ar text,
    prepared_by uuid,
    prepared_at timestamp with time zone DEFAULT now() NOT NULL,
    approved_by uuid,
    approved_at timestamp with time zone,
    fares_ref text,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT staff_late_actions_pkey PRIMARY KEY (id),
    CONSTRAINT staff_late_actions_kind_check CHECK ((kind = ANY (ARRAY['notice'::text, 'deduction'::text])))
);
CREATE INDEX ix_staff_late_actions_fy ON v2.staff_late_actions USING btree (school_id, person_id, fiscal_year) WHERE (voided_at IS NULL);
ALTER TABLE v2.staff_late_actions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.staff_late_actions IS 'تنبيهُ التأخّر وقرارُ الحسم — س-١٦-ا-١ سياسة ٠٣ ص٣٢٦ ومصفوفةُ ص٣٢٩ وص٣٣٠. ويُعدُّهما المساعدُ الإداريّ، ويعتمد قرارَ الحسم مديرُ المدرسة، ثمّ يُرفع في فارس — ورفعُه هناك خارجُ هذا النظام، وfares_ref موضعُ مرجعِه.';
