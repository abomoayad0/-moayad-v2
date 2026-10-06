-- v2.behavior_plans
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 a15183c8cbb5956c6ab48243f28ce854

CREATE TABLE v2.behavior_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    record_id uuid NOT NULL,
    student_id uuid NOT NULL,
    starts_on date,
    ends_on date,
    problem_desc text,
    manifestations text,
    antecedents text,
    consequences text,
    student_gain text,
    prior_actions text,
    target_behavior text,
    steps text[],
    deputy_opinion text,
    teacher_opinion text,
    guardian_opinion text,
    owner_person uuid,
    status text DEFAULT 'draft'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT behavior_plans_pkey PRIMARY KEY (id),
    CONSTRAINT behavior_plans_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'closed'::text]))),
    CONSTRAINT plan_dates CHECK (((ends_on IS NULL) OR (starts_on IS NULL) OR (ends_on >= starts_on)))
);
ALTER TABLE v2.behavior_plans ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.behavior_plans IS 'خطة تعديل السلوك بأقسامها الستة كما في نموذج قواعد السلوك والمواظبة CONDUCT-1447-OFF ص59–60.';
