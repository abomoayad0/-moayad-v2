-- v2.committees
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 5712100f0a0e7ef4db702b6331367fa0

CREATE TABLE v2.committees (
    key text NOT NULL,
    label_ar text NOT NULL,
    is_permanent boolean NOT NULL,
    requires_note text,
    purpose text,
    source_page text NOT NULL,
    quorum_min smallint,
    quorum_note text,
    school_id uuid,
    is_active boolean DEFAULT true NOT NULL,
    created_by uuid,
    CONSTRAINT committees_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.committees ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.committees.quorum_min IS 'اجتهادٌ لا نصّ: الدليلُ التنظيميُّ لا يذكر نصابًا للّجان';
COMMENT ON COLUMN v2.committees.school_id IS 'فارغٌ = لجنةٌ وزاريّةٌ بنصّ الدليل التنظيميّ، لا تُنشأ ولا تُحذف. ومملوءٌ = لجنةُ مدرسةٍ، اجتهادٌ لا نصَّ له. ٦/١٠/٢٠٢٦';
