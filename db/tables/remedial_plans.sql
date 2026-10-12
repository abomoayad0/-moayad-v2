-- v2.remedial_plans
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 8f8166d7ff98829378d8ae299eb1e08b

CREATE TABLE v2.remedial_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint NOT NULL,
    kind text NOT NULL,
    subject_ar text NOT NULL,
    grade smallint,
    title_ar text NOT NULL,
    class_by text DEFAULT 'skill'::text NOT NULL,
    lesson_id uuid,
    skill_id uuid,
    student_id uuid,
    source_report uuid,
    owner_person uuid,
    state text DEFAULT 'draft'::text NOT NULL,
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    review_note text,
    enrich_needed boolean DEFAULT false NOT NULL,
    approved_by uuid,
    approved_at timestamp with time zone,
    approve_note text,
    improved boolean,
    evaluated_by uuid,
    evaluated_at timestamp with time zone,
    evaluate_note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT remedial_plans_pkey PRIMARY KEY (id),
    CONSTRAINT remedial_plans_class_by_check CHECK ((class_by = ANY (ARRAY['lesson'::text, 'skill'::text]))),
    CONSTRAINT remedial_plans_class_ck CHECK ((((class_by = 'skill'::text) AND (skill_id IS NOT NULL)) OR ((class_by = 'lesson'::text) AND (lesson_id IS NOT NULL)))),
    CONSTRAINT remedial_plans_kind_check CHECK ((kind = ANY (ARRAY['individual'::text, 'group'::text]))),
    CONSTRAINT remedial_plans_state_check CHECK ((state = ANY (ARRAY['draft'::text, 'reviewed'::text, 'approved'::text, 'running'::text, 'evaluated'::text]))),
    CONSTRAINT remedial_plans_target_ck CHECK ((((kind = 'individual'::text) AND (student_id IS NOT NULL)) OR ((kind = 'group'::text) AND (student_id IS NULL))))
);
CREATE INDEX ix_remedial_plans_term ON v2.remedial_plans USING btree (school_id, term_no) WHERE (voided_at IS NULL);
ALTER TABLE v2.remedial_plans ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.remedial_plans IS 'الخطّةُ العلاجيّة — س-٩-ا-٢ ص٢٢٢–٢٢٥. فرديّةٌ أو جماعيّةٌ بنصّ سياسة ٠١، ومصنَّفةٌ «حسب الدروس والمهارات» بنصّ خطوة ٠١. وحالاتُها تمشي على الخطوات الستّ: المعلّمُ يُعدّ · لجنةُ التوجيه تراجع الجماعيّةَ · الوكيلُ للشؤون التعليميّة يعتمد · المعلّمُ ينفّذ · الموجّهُ يتابع · واللجنةُ تُقيّم.';
