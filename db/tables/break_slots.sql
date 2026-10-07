-- v2.break_slots
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 810bf205f91f7de563799c675e2cbbad

CREATE TABLE v2.break_slots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    kind text NOT NULL,
    label_ar text NOT NULL,
    starts_at time without time zone NOT NULL,
    ends_at time without time zone NOT NULL,
    after_period smallint,
    needs_duty boolean DEFAULT true NOT NULL,
    min_staff smallint,
    note_ar text,
    active boolean DEFAULT true NOT NULL,
    CONSTRAINT break_slots_pkey PRIMARY KEY (id),
    CONSTRAINT break_slots_check CHECK ((ends_at > starts_at)),
    CONSTRAINT break_slots_kind_check CHECK ((kind = ANY (ARRAY['فسحة'::text, 'صلاة'::text, 'اصطفاف'::text, 'انصراف'::text, 'أخرى'::text])))
);
CREATE INDEX ix_bs_school ON v2.break_slots USING btree (school_id, starts_at);
ALTER TABLE v2.break_slots ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.break_slots IS 'فتراتُ اليوم غيرُ الحصص — الفسحةُ والصلاةُ والاصطفافُ والانصراف. يُرصد فيها السلوكُ بمكانٍ معروف، ويُجدوَل عليها الإشراف. ٦/١٠/٢٠٢٦';
