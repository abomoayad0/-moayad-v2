-- v2.conduct_problems
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 1d4d569097189d1782e93cd4eb603867

CREATE TABLE v2.conduct_problems (
    id integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    degree_no smallint NOT NULL,
    stage_scope text NOT NULL,
    mode text NOT NULL,
    target text NOT NULL,
    item_no smallint NOT NULL,
    text_ar text NOT NULL,
    article_no smallint NOT NULL,
    source_doc text NOT NULL,
    source_page text NOT NULL,
    once_per_day boolean DEFAULT false NOT NULL,
    repeat_key text,
    advice_waived_ar text,
    CONSTRAINT conduct_problems_pkey PRIMARY KEY (id),
    CONSTRAINT conduct_problems_degree_no_stage_scope_mode_target_item_no_key UNIQUE (degree_no, stage_scope, mode, target, item_no),
    CONSTRAINT conduct_problems_mode_check CHECK ((mode = ANY (ARRAY['onsite'::text, 'online'::text]))),
    CONSTRAINT conduct_problems_repeat_key_check CHECK ((repeat_key = ANY (ARRAY['day'::text, 'period'::text, 'time'::text]))),
    CONSTRAINT conduct_problems_stage_scope_check CHECK ((stage_scope = ANY (ARRAY['primary'::text, 'intermediate_secondary'::text, 'all'::text]))),
    CONSTRAINT conduct_problems_target_check CHECK ((target = ANY (ARRAY['general'::text, 'staff'::text]))),
    CONSTRAINT conduct_problems_text_ar_check CHECK ((btrim(text_ar) <> ''::text))
);
CREATE INDEX conduct_problems_idx ON v2.conduct_problems USING btree (stage_scope, mode, degree_no);
ALTER TABLE v2.conduct_problems ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.conduct_problems IS 'المشكلات السلوكية من قواعد السلوك والمواظبة لطلبة التعليم العام، الإصدار الخامس 1447هـ. مرجع يُقرأ للجميع ولا يكتبه أحد من المدرسة.';
COMMENT ON COLUMN v2.conduct_problems.once_per_day IS 'حالٌ تدوم اليومَ كلَّه أو فعلٌ لا يُعاد فيه — فلا تُدوَّن مرّتين. اجتهادُ مدرسةٍ: الدليلُ لا يصنّفها، والتصنيفُ من طبيعة السلوك. ٦/١٠/٢٠٢٦';
COMMENT ON COLUMN v2.conduct_problems.repeat_key IS 'ما يميّز الواقعةَ حين تتكرّر: period = الحصّة · time = الوقت · day = اليوم';
COMMENT ON COLUMN v2.conduct_problems.advice_waived_ar IS 'إن كُتب هنا سببٌ فلا نصيحةَ لهذي المخالفة بقرار — ويُعرض السببُ على الراصد مكان إعلان النقص';
