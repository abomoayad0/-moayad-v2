-- v2.cover_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 ea3beb972be92a14367ebbfa46bc46b0

CREATE TABLE v2.cover_rules (
    school_id uuid NOT NULL,
    auto_on boolean DEFAULT true NOT NULL,
    max_per_day smallint DEFAULT 2 NOT NULL,
    prefer_same_subject boolean DEFAULT false NOT NULL,
    allow_teaching_free boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by uuid,
    CONSTRAINT cover_rules_pkey PRIMARY KEY (school_id),
    CONSTRAINT cover_rules_max_ck CHECK (((max_per_day >= 1) AND (max_per_day <= 7)))
);
ALTER TABLE v2.cover_rules ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.cover_rules.max_per_day IS 'الحدُّ الأعلى لتغطيات المعلّم في اليوم الواحد — عدلًا بنصّ سياسة ٠١ من س-٨-ا-١';
COMMENT ON COLUMN v2.cover_rules.prefer_same_subject IS 'تقديمُ معلّم المادة نفسها على ترتيب العدل — مطفأٌ افتراضًا لأنّ العدلَ هو المنصوص';
COMMENT ON COLUMN v2.cover_rules.allow_teaching_free IS 'إسنادُ التغطية لمن لا خانةَ انتظارٍ له لكنّه فارغٌ آنئذٍ — مطفأٌ افتراضًا لأنّ الدليلَ يضع الاحتياطَ في الجدول المعتمد';
