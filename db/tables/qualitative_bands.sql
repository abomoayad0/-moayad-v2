-- v2.qualitative_bands
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 8338439b0af785dd6aed66b0bee4a460

CREATE TABLE v2.qualitative_bands (
    domain text NOT NULL,
    min_points numeric NOT NULL,
    label_ar text NOT NULL,
    ord smallint NOT NULL,
    school_id uuid,
    CONSTRAINT qualitative_bands_pkey PRIMARY KEY (domain, ord, min_points)
);
ALTER TABLE v2.qualitative_bands ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.qualitative_bands IS 'حدودُ التقدير الكيفيّ · الدليلُ أوجب التقديرَ الكيفيَّ للصفّين الأوّل والثاني ولم يُسمِّ حدودَه — فهذي حدودٌ من عندنا تُضبط من لوحة التحكّم، ولا تُنسب إلى الدليل';
