-- v2.hijri_months
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 dc4201e2bc936c0d4f9a342e240e1416

CREATE TABLE v2.hijri_months (
    h_year smallint NOT NULL,
    h_month smallint NOT NULL,
    starts_g date NOT NULL,
    days_count smallint NOT NULL,
    source text DEFAULT 'تقويم أم القرى — قوبل بالتواريخ الهجرية المطبوعة في جداول الأسابيع فطابقها في 76 موضعاً بلا فرق'::text NOT NULL,
    CONSTRAINT hijri_months_pkey PRIMARY KEY (h_year, h_month)
);
ALTER TABLE v2.hijri_months ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.hijri_months IS 'أوائل الشهور الهجرية بتقويم أم القرى، لتحويل التاريخ الميلادي إلى هجري داخل القاعدة. وقد قوبلت بالتواريخ المطبوعة في تقويم 1448/1449 فطابقتها في كل حدود الأسابيع الستة والسبعين.';
