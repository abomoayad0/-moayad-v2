-- v2.conduct_universal
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 5c49be9e25781a427e160a3c287cb7c3

CREATE TABLE v2.conduct_universal (
    id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    degree_no smallint NOT NULL,
    stage_scope text NOT NULL,
    mode text NOT NULL,
    target text NOT NULL,
    item_no smallint NOT NULL,
    body_ar text NOT NULL,
    article_no smallint NOT NULL,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT conduct_universal_pkey PRIMARY KEY (id),
    CONSTRAINT conduct_universal_degree_no_stage_scope_mode_target_item_no_key UNIQUE (degree_no, stage_scope, mode, target, item_no),
    CONSTRAINT conduct_universal_body_ar_check CHECK ((btrim(body_ar) <> ''::text)),
    CONSTRAINT conduct_universal_mode_check CHECK ((mode = ANY (ARRAY['onsite'::text, 'online'::text]))),
    CONSTRAINT conduct_universal_stage_scope_check CHECK ((stage_scope = ANY (ARRAY['primary'::text, 'intermediate_secondary'::text, 'all'::text]))),
    CONSTRAINT conduct_universal_target_check CHECK ((target = ANY (ARRAY['general'::text, 'staff'::text])))
);
ALTER TABLE v2.conduct_universal ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.conduct_universal IS 'بنود «في جميع الإجراءات» الملحقة بآخر كل مادة من مواد المشكلات السلوكية — تسري على إجراءات تلك المادة كلها لا على خطوة بعينها.';
