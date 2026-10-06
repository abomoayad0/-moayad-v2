-- v2.absence_ladder
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 0e1010da3f56c027c96d43a0c598b2bd

CREATE TABLE v2.absence_ladder (
    id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    excused boolean NOT NULL,
    days smallint NOT NULL,
    body_ar text NOT NULL,
    note_ar text,
    refers_counselor boolean DEFAULT false NOT NULL,
    refers_committee boolean DEFAULT false NOT NULL,
    summons_guardian boolean DEFAULT false NOT NULL,
    escalates_external boolean DEFAULT false NOT NULL,
    article_no smallint NOT NULL,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT absence_ladder_pkey PRIMARY KEY (id),
    CONSTRAINT absence_ladder_excused_days_key UNIQUE (excused, days),
    CONSTRAINT absence_ladder_body_ar_check CHECK ((btrim(body_ar) <> ''::text)),
    CONSTRAINT absence_ladder_days_check CHECK ((days > 0))
);
ALTER TABLE v2.absence_ladder ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.absence_ladder IS 'إجراءات التعامل مع المتغيبين: صفوف لكل عدد أيام غياب، مفصولة بين الغياب بعذر وبغير عذر.';
