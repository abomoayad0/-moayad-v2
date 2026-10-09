-- v2.citations
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 4885f98cd1b3f793ae851e41b3a83687

CREATE TABLE v2.citations (
    key text NOT NULL,
    label_ar text,
    article_no smallint,
    clause_no smallint,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    note_ar text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    source_edition text,
    CONSTRAINT citations_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.citations ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.citations IS 'مصدرٌ واحدٌ لاستشهادات الأدلّة غيرِ المنقولة في conduct_rules — ويُصحَّح بسطرٍ لا بهجرة';
COMMENT ON COLUMN v2.citations.source_edition IS 'إصدارُ الدليل — فالحكمُ يتغيّر بالإصدار، والصفحةُ بلا إصدارٍ ناقصة';
