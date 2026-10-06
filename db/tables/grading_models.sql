-- v2.grading_models
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 dbe2d6e64b30e8fa3d5a312a3133eaf1

CREATE TABLE v2.grading_models (
    model_no smallint NOT NULL,
    kind text NOT NULL,
    title_ar text NOT NULL,
    total smallint DEFAULT 100 NOT NULL,
    components jsonb NOT NULL,
    retake_note text,
    notes_ar text[],
    source_doc text DEFAULT 'GRADE-2025-OFF'::text NOT NULL,
    source_page text NOT NULL,
    CONSTRAINT grading_models_pkey PRIMARY KEY (model_no),
    CONSTRAINT grading_models_kind_check CHECK ((kind = ANY (ARRAY['تكويني'::text, 'ختامي'::text, 'سلوك'::text, 'مواظبة'::text, 'نشاط'::text, 'اختياري'::text])))
);
ALTER TABLE v2.grading_models ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.grading_models IS 'نماذج تقويم المواد الاثنا عشر من «توزيع درجات المواد الدراسية 2025» — وزارة التعليم. كل نموذج بمكوّناته ودرجاتها وحكم الدور الثاني فيه.';
