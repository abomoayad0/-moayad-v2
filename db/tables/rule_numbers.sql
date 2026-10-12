-- v2.rule_numbers
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 0e178a9cf91397057259b0cba3a338c2

CREATE TABLE v2.rule_numbers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid,
    key text NOT NULL,
    label_ar text NOT NULL,
    value_n integer NOT NULL,
    unit_ar text NOT NULL,
    min_n integer,
    max_n integer,
    source_kind text NOT NULL,
    source_ar text,
    why_ar text NOT NULL,
    editable boolean DEFAULT true NOT NULL,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT rule_numbers_pkey PRIMARY KEY (id),
    CONSTRAINT rule_numbers_source_kind_check CHECK ((source_kind = ANY (ARRAY['dalil'::text, 'school'::text, 'ijtihad'::text])))
);
CREATE UNIQUE INDEX ux_rule_numbers_key ON v2.rule_numbers USING btree (school_id, key) NULLS NOT DISTINCT;
ALTER TABLE v2.rule_numbers ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.rule_numbers IS 'مرجعُ الأرقام — لا رقمَ عتبةٍ في جسم دالّة. والصفُّ بلا مدرسةٍ هو الافتراض، وصفُّ المدرسة يسبقه.';
