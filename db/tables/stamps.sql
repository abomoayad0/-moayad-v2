-- v2.stamps
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 2793c631edc0ee8f4803136b5f7a6f3a

CREATE TABLE v2.stamps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    image_ref text NOT NULL,
    valid_from date DEFAULT CURRENT_DATE NOT NULL,
    valid_to date,
    CONSTRAINT stamps_pkey PRIMARY KEY (id),
    CONSTRAINT stamps_check CHECK (((valid_to IS NULL) OR (valid_to >= valid_from))),
    CONSTRAINT stamps_image_ref_check CHECK ((length(btrim(image_ref)) > 0))
);
CREATE UNIQUE INDEX stamps_one_current ON v2.stamps USING btree (school_id) WHERE (valid_to IS NULL);
ALTER TABLE v2.stamps ENABLE ROW LEVEL SECURITY;
