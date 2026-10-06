-- v2.conduct_merits
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f30b1734c5eb7250897273fd979010cb

CREATE TABLE v2.conduct_merits (
    id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    group_ar text NOT NULL,
    text_ar text NOT NULL,
    points smallint,
    points_note text,
    per_participation boolean DEFAULT false NOT NULL,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT conduct_merits_pkey PRIMARY KEY (id),
    CONSTRAINT conduct_merits_text_ar_check CHECK ((btrim(text_ar) <> ''::text))
);
ALTER TABLE v2.conduct_merits ENABLE ROW LEVEL SECURITY;
