-- v2.curriculum_books
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 cbdf7bea15501dbc1b1a63ea7fb0de30

CREATE TABLE v2.curriculum_books (
    id uuid NOT NULL,
    stage text,
    grade smallint,
    subject_ar text,
    term_no smallint,
    title_ar text,
    pages integer,
    part_no smallint,
    part_title text,
    file_ref text,
    page_prefix text,
    book_kind text,
    source text,
    verified boolean DEFAULT false NOT NULL,
    imported_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT curriculum_books_pkey PRIMARY KEY (id)
);
ALTER TABLE v2.curriculum_books ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.curriculum_books IS 'كتبُ المنهج ومراجعُ ملفّاتها. والمرحلةُ محسوبةٌ من الصفّ — فالقديمُ لم يحملها.';
