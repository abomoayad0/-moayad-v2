-- v2.behavior_ledger
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 285ba126fdfd9e7f88edfa98021fa20e

CREATE TABLE v2.behavior_ledger (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint NOT NULL,
    student_id uuid NOT NULL,
    kind text NOT NULL,
    points numeric NOT NULL,
    record_id uuid,
    merit_id integer,
    reason text NOT NULL,
    by_person uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT behavior_ledger_pkey PRIMARY KEY (id),
    CONSTRAINT behavior_ledger_kind_check CHECK ((kind = ANY (ARRAY['opening'::text, 'deduction'::text, 'compensation'::text, 'merit'::text, 'veto'::text])))
);
CREATE INDEX bl_student_idx ON v2.behavior_ledger USING btree (student_id, year_id, term_no);
ALTER TABLE v2.behavior_ledger ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.behavior_ledger IS 'حركة درجات السلوك: 80 افتتاحية لكل فصل، ثم حسم وتعويض ونقض. الرصيد = مجموع الحركات، ولا يتجاوز 100.';
