-- v2.absence_excuses
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6fa0c7cd347c680aa39f582a45603f12

CREATE TABLE v2.absence_excuses (
    item_no smallint NOT NULL,
    text_ar text NOT NULL,
    proof_ar text,
    school_discretion boolean DEFAULT false NOT NULL,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT absence_excuses_pkey PRIMARY KEY (item_no),
    CONSTRAINT absence_excuses_text_ar_check CHECK ((btrim(text_ar) <> ''::text))
);
ALTER TABLE v2.absence_excuses ENABLE ROW LEVEL SECURITY;
