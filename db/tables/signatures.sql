-- v2.signatures
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f77f1214e2ad626c360a2083d1c9fd7c

CREATE TABLE v2.signatures (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    person_id uuid NOT NULL,
    image_ref text NOT NULL,
    valid_from date DEFAULT CURRENT_DATE NOT NULL,
    valid_to date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT signatures_pkey PRIMARY KEY (id),
    CONSTRAINT signatures_check CHECK (((valid_to IS NULL) OR (valid_to >= valid_from))),
    CONSTRAINT signatures_image_ref_check CHECK ((length(btrim(image_ref)) > 0))
);
CREATE UNIQUE INDEX signatures_one_current ON v2.signatures USING btree (person_id) WHERE (valid_to IS NULL);
ALTER TABLE v2.signatures ENABLE ROW LEVEL SECURITY;
