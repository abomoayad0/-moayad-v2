-- v2.teaching_ranks
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 9350de55a1e31ef35a9df2daaa94abbf

CREATE TABLE v2.teaching_ranks (
    key text NOT NULL,
    label_ar text NOT NULL,
    ord smallint NOT NULL,
    periods_general smallint NOT NULL,
    periods_sen smallint NOT NULL,
    source_doc text DEFAULT 'ORG-1442-OFF'::text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT teaching_ranks_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.teaching_ranks ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.teaching_ranks IS 'الرتب التعليمية ونصابها الأسبوعي. ORG-1442-OFF ص10 بند 21: «يكون نصاب المعلم الممارس 24 حصة ونصاب المعلم المتقدم 22 حصة ونصاب المعلم الخبير 18 حصة». وص44 بند 26 لمعلم التربية الخاصة: 16 و14 و12.';
