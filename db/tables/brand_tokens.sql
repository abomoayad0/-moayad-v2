-- v2.brand_tokens
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 35718a3aad8f8cb73865d08518c930ad

CREATE TABLE v2.brand_tokens (
    token_key text NOT NULL,
    kind text NOT NULL,
    group_name text NOT NULL,
    label_ar text NOT NULL,
    value text,
    ord smallint,
    is_substitute boolean DEFAULT false NOT NULL,
    original_value text,
    source_doc text NOT NULL,
    source_page text,
    note text,
    CONSTRAINT brand_tokens_pkey PRIMARY KEY (token_key),
    CONSTRAINT brand_tokens_kind_check CHECK ((kind = ANY (ARRAY['color'::text, 'font'::text, 'rule'::text, 'asset'::text])))
);
ALTER TABLE v2.brand_tokens ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.brand_tokens IS 'مرجع الهوية البصرية — منقول من دليل الهوية البصرية لوزارة التعليم، الإصدار الثالث، أكتوبر 2025. مرجع يُقرأ للجميع ولا يكتبه أحد من المدرسة.';
COMMENT ON COLUMN v2.brand_tokens.is_substitute IS 'true يعني أن القيمة بديل عن الأصل المذكور في original_value، لتعذّر الأصل.';
