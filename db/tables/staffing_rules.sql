-- v2.staffing_rules
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 7a023f76f2b2f9cc1f81c79d50c80686

CREATE TABLE v2.staffing_rules (
    id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
    stage text NOT NULL,
    category text DEFAULT 'all'::text NOT NULL,
    post_key text NOT NULL,
    basis text NOT NULL,
    min_value integer,
    max_value integer,
    grants_count smallint,
    grants_assigned boolean DEFAULT false NOT NULL,
    source_page text NOT NULL,
    note text,
    CONSTRAINT staffing_rules_pkey PRIMARY KEY (id),
    CONSTRAINT staffing_rules_basis_check CHECK ((basis = ANY (ARRAY['classes'::text, 'students'::text]))),
    CONSTRAINT staffing_rules_check CHECK (((min_value IS NOT NULL) OR (max_value IS NOT NULL)))
);
ALTER TABLE v2.staffing_rules ENABLE ROW LEVEL SECURITY;
