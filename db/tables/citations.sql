-- v2.citations
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 40d2af34c2818221cafc1bcfbc139b49

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
    CONSTRAINT citations_pkey PRIMARY KEY (key)
);
ALTER TABLE v2.citations ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.citations IS 'مصدرٌ واحدٌ لاستشهادات الأدلّة غيرِ المنقولة في conduct_rules — ويُصحَّح بسطرٍ لا بهجرة';
