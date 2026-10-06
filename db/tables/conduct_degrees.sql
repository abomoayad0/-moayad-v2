-- v2.conduct_degrees
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6ec17b2136cc2a70f93b39b184f0a317

CREATE TABLE v2.conduct_degrees (
    degree_no smallint NOT NULL,
    label_ar text NOT NULL,
    deduction smallint NOT NULL,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT conduct_degrees_pkey PRIMARY KEY (degree_no),
    CONSTRAINT conduct_degrees_deduction_check CHECK ((deduction > 0)),
    CONSTRAINT conduct_degrees_degree_no_check CHECK (((degree_no >= 1) AND (degree_no <= 5)))
);
ALTER TABLE v2.conduct_degrees ENABLE ROW LEVEL SECURITY;
