-- v2.calendar_week_overrides
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 db5ab3889e1c9ae0a1d6ff14f8cffce6

CREATE TABLE v2.calendar_week_overrides (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    week_id uuid NOT NULL,
    from_h text,
    from_g date,
    to_h text,
    to_g date,
    is_exam_week boolean,
    note_ar text,
    reason_ar text NOT NULL,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    authority text DEFAULT 'school'::text NOT NULL,
    CONSTRAINT calendar_week_overrides_pkey PRIMARY KEY (id),
    CONSTRAINT cwo_authority_check CHECK ((authority = ANY (ARRAY['school'::text, 'edu_dept'::text, 'ministry'::text])))
);
CREATE INDEX ix_cwo_school ON v2.calendar_week_overrides USING btree (school_id);
CREATE UNIQUE INDEX ux_cwo_live ON v2.calendar_week_overrides USING btree (school_id, week_id) WHERE (voided_at IS NULL);
ALTER TABLE v2.calendar_week_overrides ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.calendar_week_overrides IS 'تخصيصُ مدرسةٍ لأسبوعٍ في تقويم مسارها — والأصلُ باقٍ لا يُمسّ، وتقويمُ المدارس الأخرى لا يتغيّر. والإعادةُ إلى الأصل إبطالٌ مُسجَّلٌ بسببه لا حذف.';
COMMENT ON COLUMN v2.calendar_week_overrides.reason_ar IS 'سببُ التخصيص — إلزاميّ. فمن يقرأ التقويمَ بعد سنتين يعرف لِمَ خُصِّص ومن خصَّصه.';
COMMENT ON COLUMN v2.calendar_week_overrides.authority IS 'جهةُ التخصيص: school (المدرسة — لا تُنقص أسابيعَ الدراسة) · edu_dept (إدارةُ التعليم) · ministry (الوزارة). ويُثبّتها إدارةُ النظام لا المدرسة.';
