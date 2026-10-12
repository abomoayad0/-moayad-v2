-- v2.lesson_plans
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 ea72686a7e8d87f8a40b8a2cad7fa9ac

CREATE TABLE v2.lesson_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint NOT NULL,
    grade smallint NOT NULL,
    subject_ar text NOT NULL,
    owner_person uuid,
    status text DEFAULT 'draft'::text NOT NULL,
    source text DEFAULT 'محسوب'::text NOT NULL,
    prepared_by uuid,
    prepared_at timestamp with time zone,
    review_assignee uuid,
    assigned_by uuid,
    assigned_at timestamp with time zone,
    assign_why text,
    review_path text,
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    review_note text,
    approved_by uuid,
    approved_at timestamp with time zone,
    approved_without_review boolean DEFAULT false NOT NULL,
    is_locked boolean DEFAULT false NOT NULL,
    locked_by uuid,
    locked_at timestamp with time zone,
    lock_why text,
    note_ar text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    built_at timestamp with time zone,
    build_no smallint DEFAULT 0 NOT NULL,
    CONSTRAINT lesson_plans_pkey PRIMARY KEY (id),
    CONSTRAINT lesson_plans_grade_check CHECK (((grade >= 1) AND (grade <= 12))),
    CONSTRAINT lesson_plans_review_path_check CHECK ((review_path = ANY (ARRAY['expert'::text, 'advanced'::text, 'assigned_by_principal'::text, 'none'::text]))),
    CONSTRAINT lesson_plans_source_check CHECK ((source = ANY (ARRAY['محسوب'::text, 'بيد المعلم'::text, 'بيد الوكيل'::text]))),
    CONSTRAINT lesson_plans_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'prepared'::text, 'reviewed'::text, 'approved'::text]))),
    CONSTRAINT lesson_plans_term_no_check CHECK ((term_no = ANY (ARRAY[1, 2])))
);
CREATE INDEX ix_lesson_plans_owner ON v2.lesson_plans USING btree (owner_person);
CREATE INDEX ix_lesson_plans_school ON v2.lesson_plans USING btree (school_id, status);
CREATE UNIQUE INDEX ux_lesson_plans_owner ON v2.lesson_plans USING btree (school_id, term_no, grade, subject_ar, owner_person);
ALTER TABLE v2.lesson_plans ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.lesson_plans IS 'الخطّةُ الفصليّةُ لتوزيع منهج مادّةٍ على صفٍّ في مدرسة — رأسُ التوزيع وسلّمُ اعتماده. توزيعٌ واحدٌ للمادّة في الصفّ لا لكلّ فصل. مرجعُها: دليل إجراءات العمل س-8-ا-2 ص٢٠٣–٢٠٨.';
COMMENT ON COLUMN v2.lesson_plans.status IS 'draft مُسوَّدة · prepared أعدَّها المعلّم · reviewed رُوجعت · approved اعتمدها الوكيلُ للشؤون التعليميّة. ولا يعتمد المعلّمُ لنفسه.';
COMMENT ON COLUMN v2.lesson_plans.source IS 'مصدرُ التوزيع: محسوبٌ آليًّا · أو بيد المعلّم · أو بيد الوكيل. نيّةٌ مُعلَنةٌ لا مخبوءةٌ في كود.';
COMMENT ON COLUMN v2.lesson_plans.review_path IS 'بأيّ سبيلٍ رُوجعت: expert معلّمٌ خبير · advanced معلّمٌ متقدّمٌ لخلوّ الخبير (نصُّ الدليل ص٩٩) · assigned_by_principal كلَّف المديرُ مراجعًا لخلوّ الاثنين · none لم تُراجع.';
COMMENT ON COLUMN v2.lesson_plans.approved_without_review IS 'اعتُمدت بلا مراجعةٍ — تُعرض موسومةً في لوحة الوكيل بعددٍ، ولا تُخفى.';
COMMENT ON COLUMN v2.lesson_plans.is_locked IS 'أُقفل التعديلُ — ويُقفله الوكيلُ عند دخول أسبوع الاختبار. والرصدُ يبقى مفتوحًا.';
COMMENT ON COLUMN v2.lesson_plans.build_no IS 'كم مرّةً أُعيد حسابُ هذي الخطّة آليًّا.';
