-- v2.form_row_schema
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 cb73f26dffaa15efdbb189ed89dffd43

CREATE TABLE v2.form_row_schema (
    form_no smallint NOT NULL,
    key text NOT NULL,
    label_ar text NOT NULL,
    input text NOT NULL,
    options text[],
    ord smallint DEFAULT 0 NOT NULL,
    CONSTRAINT form_row_schema_pkey PRIMARY KEY (form_no, key),
    CONSTRAINT form_row_schema_input_check CHECK ((input = ANY (ARRAY['text'::text, 'longtext'::text, 'date'::text, 'time'::text, 'number'::text, 'select'::text, 'checkbox'::text, 'auto'::text, 'derived'::text])))
);
ALTER TABLE v2.form_row_schema ENABLE ROW LEVEL SECURITY;
