-- v2.delegations
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 cdf56f4289ca6a7f5d86a34dc5fc3011

CREATE TABLE v2.delegations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    post_key text NOT NULL,
    from_person uuid,
    to_person uuid NOT NULL,
    starts_on date DEFAULT CURRENT_DATE NOT NULL,
    ends_on date,
    reason text NOT NULL,
    letter_no text,
    issued_by uuid,
    issued_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    revoked_why text,
    CONSTRAINT delegations_pkey PRIMARY KEY (id)
);
CREATE INDEX ix_dlg_live ON v2.delegations USING btree (school_id, post_key, to_person);
ALTER TABLE v2.delegations ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.delegations IS 'الإنابةُ في الصفة — فلا يتعطّل العملُ بغياب صاحبها. بمدّةٍ وسببٍ مكتوبٍ ورقمِ خطاب، وكلُّ فعلٍ بها يُقيَّد أنّه بإنابة. ٦/١٠/٢٠٢٦';
