-- v2.terms
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 b07c1fa5e4a339705272f24ace6c3134

CREATE TABLE v2.terms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    year_id uuid NOT NULL,
    number smallint NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    is_current boolean DEFAULT false NOT NULL,
    CONSTRAINT terms_pkey PRIMARY KEY (id),
    CONSTRAINT terms_year_id_number_key UNIQUE (year_id, number),
    CONSTRAINT terms_check CHECK ((ends_on > starts_on)),
    CONSTRAINT terms_number_check CHECK (((number >= 1) AND (number <= 3)))
);
CREATE UNIQUE INDEX terms_one_current ON v2.terms USING btree (year_id) WHERE is_current;
ALTER TABLE v2.terms ENABLE ROW LEVEL SECURITY;
