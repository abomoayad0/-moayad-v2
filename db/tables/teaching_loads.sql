-- v2.teaching_loads
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 5f03e7fa9605f286a3c93f520524b9bb

CREATE TABLE v2.teaching_loads (
    rank_ar text NOT NULL,
    periods smallint NOT NULL,
    scope_ar text NOT NULL,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    item_no smallint,
    CONSTRAINT teaching_loads_pkey PRIMARY KEY (rank_ar)
);
ALTER TABLE v2.teaching_loads ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.teaching_loads IS 'نصاب المعلم الأسبوعي. الدليل التنظيمي ORG-1442-OFF ص10 بند 21: «يكون نصاب المعلم الممارس 24 حصة ونصاب المعلم المتقدم 22 حصة ونصاب المعلم الخبير 18 حصة». وص44 بند 26 لمعلم التربية الخاصة: 16 و14 و12.';
