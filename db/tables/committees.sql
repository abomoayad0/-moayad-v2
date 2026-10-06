-- v2.committees
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 a505ad7ec462b0091b3681c71b751c95

CREATE TABLE v2.committees (
    key text NOT NULL,
    label_ar text NOT NULL,
    is_permanent boolean NOT NULL,
    requires_note text,
    purpose text,
    source_page text NOT NULL,
    quorum_min smallint,
    quorum_note text,
    CONSTRAINT committees_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.committees ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.committees.quorum_min IS 'اجتهادٌ لا نصّ: الدليلُ التنظيميُّ لا يذكر نصابًا للّجان';
