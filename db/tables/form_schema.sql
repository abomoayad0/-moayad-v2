-- v2.form_schema
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d79cb4a6d0872a5c82d46d7c8015f89d

CREATE TABLE v2.form_schema (
    form_no smallint NOT NULL,
    key text NOT NULL,
    label_ar text NOT NULL,
    input text NOT NULL,
    options text[],
    required boolean DEFAULT false NOT NULL,
    ord smallint DEFAULT 0 NOT NULL,
    hint_ar text,
    filled_by_ar text,
    derived_from text,
    derive_kind text,
    CONSTRAINT form_schema_pkey PRIMARY KEY (form_no, key),
    CONSTRAINT form_schema_input_check CHECK ((input = ANY (ARRAY['text'::text, 'longtext'::text, 'date'::text, 'time'::text, 'number'::text, 'select'::text, 'checkbox'::text, 'auto'::text, 'derived'::text])))
);
ALTER TABLE v2.form_schema ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.form_schema IS 'مخطّط إدخال النموذج: لكل حقل نوعه وهل هو إلزامي. input=auto يعني يُملأ من القاعدة ولا يُكتب.';
