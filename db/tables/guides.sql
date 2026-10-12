-- v2.guides
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1c0b9a2beb90b2ab1fe11c6f908ea4c0

CREATE TABLE v2.guides (
    id uuid NOT NULL,
    code text NOT NULL,
    title_ar text,
    authority_kind text,
    is_binding boolean,
    issuer_ar text,
    author_ar text,
    edition_ar text,
    pages_ar text,
    topic_ar text,
    body_ar text,
    source_note_ar text,
    page_count integer,
    transcription_source text,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT guides_pkey PRIMARY KEY (id),
    CONSTRAINT guides_code_key UNIQUE (code)
);
ALTER TABLE v2.guides ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.guides IS 'الأدلّةُ الرسميّةُ ومراجعُها — بطاقةُ كلّ دليلٍ ورمزُه وإصدارُه وهل هو مُلزِم. نُقل من مشروع moayad ٩/١٠/٢٠٢٦.';
