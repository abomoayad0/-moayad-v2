-- v2.guide_pages
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 93c7b0d2e024fb497b46d18f784b7613

CREATE TABLE v2.guide_pages (
    id uuid NOT NULL,
    guide_id uuid NOT NULL,
    part_no smallint,
    page_file integer,
    page_print text,
    content_kind text,
    body text,
    table_rows integer,
    doubtful boolean DEFAULT false,
    doubt_note text,
    transcribed_by text,
    transcribed_at timestamp with time zone,
    verified_by text,
    verified_at timestamp with time zone,
    content_missing boolean DEFAULT false,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT guide_pages_pkey PRIMARY KEY (id)
);
CREATE INDEX ix_guide_pages_body ON v2.guide_pages USING gin (to_tsvector('simple'::regconfig, COALESCE(body, ''::text)));
CREATE INDEX ix_guide_pages_guide ON v2.guide_pages USING btree (guide_id, page_file);
CREATE INDEX ix_guide_pages_print ON v2.guide_pages USING btree (guide_id, page_print);
ALTER TABLE v2.guide_pages ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.guide_pages IS 'نصُّ صفحات الأدلّة منسوخًا صفحةً صفحة — ومعه وسمُ الشكّ (doubtful) وسببُه، ومن نسخ ومن قابَل. مصدرُ كلّ استشهادٍ في النظام.';
COMMENT ON COLUMN v2.guide_pages.page_print IS 'رقمُ الصفحة كما هو مطبوعٌ في الدليل — وهو الذي يُستشهد به، لا page_file.';
COMMENT ON COLUMN v2.guide_pages.doubtful IS 'لم تُقرأ بيقين — وسببُه في doubt_note. لا يُبنى على صفٍّ موسومٍ به دون مقابلة.';
