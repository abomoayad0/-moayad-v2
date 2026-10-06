-- v2.conduct_actions
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 99eab7492b0357afa773373f37b93098

CREATE TABLE v2.conduct_actions (
    id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    degree_no smallint NOT NULL,
    stage_scope text NOT NULL,
    mode text NOT NULL,
    target text NOT NULL,
    step_no smallint NOT NULL,
    body_ar text NOT NULL,
    refers_counselor boolean DEFAULT false NOT NULL,
    refers_committee boolean DEFAULT false NOT NULL,
    notifies_guardian boolean DEFAULT false NOT NULL,
    summons_guardian boolean DEFAULT false NOT NULL,
    deducts_points boolean DEFAULT false NOT NULL,
    article_no smallint NOT NULL,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT conduct_actions_pkey PRIMARY KEY (id),
    CONSTRAINT conduct_actions_degree_no_stage_scope_mode_target_step_no_key UNIQUE (degree_no, stage_scope, mode, target, step_no),
    CONSTRAINT conduct_actions_body_ar_check CHECK ((btrim(body_ar) <> ''::text)),
    CONSTRAINT conduct_actions_mode_check CHECK ((mode = ANY (ARRAY['onsite'::text, 'online'::text]))),
    CONSTRAINT conduct_actions_stage_scope_check CHECK ((stage_scope = ANY (ARRAY['primary'::text, 'intermediate_secondary'::text, 'all'::text]))),
    CONSTRAINT conduct_actions_step_no_check CHECK (((step_no >= 1) AND (step_no <= 6))),
    CONSTRAINT conduct_actions_target_check CHECK ((target = ANY (ARRAY['general'::text, 'staff'::text])))
);
ALTER TABLE v2.conduct_actions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.conduct_actions IS 'سلّم الإجراءات التربوية: عند ارتكاب المشكلة يُطبق الإجراء الأول، وعند تكرار المشكلة نفسها يُطبق الذي يليه. الأعمدة المنطقية مستخرجة من نص الإجراء لتمكين الأتمتة.';
