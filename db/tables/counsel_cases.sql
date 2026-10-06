-- v2.counsel_cases
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f6927349a3a737d6aa83c359a923bfc9

CREATE TABLE v2.counsel_cases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    record_id uuid,
    problem_id integer,
    year_id uuid,
    term_no smallint,
    source_ar text DEFAULT 'مؤشّر السلوك — قواعد السلوك والمواظبة'::text NOT NULL,
    state text DEFAULT 'قيد المعالجة'::text NOT NULL,
    opened_on date DEFAULT CURRENT_DATE NOT NULL,
    opened_by uuid,
    student_view text,
    observed text,
    factors text,
    plan_ar text,
    written_by uuid,
    written_at timestamp with time zone,
    closed_on date,
    close_reason text,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT counsel_cases_pkey PRIMARY KEY (id),
    CONSTRAINT counsel_cases_student_id_problem_id_year_id_key UNIQUE (student_id, problem_id, year_id),
    CONSTRAINT counsel_cases_state_check CHECK ((state = ANY (ARRAY['قيد المعالجة'::text, 'تمّت المعالجة'::text, 'مغلقة'::text])))
);
CREATE INDEX ix_cc_school ON v2.counsel_cases USING btree (school_id, state);
ALTER TABLE v2.counsel_cases ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.counsel_cases IS 'دراسةُ حالة الطالب — 🔒 سرّيّةٌ عند الموجّه؛ لا يراها الوكيلُ ولا اللجنةُ ولا وليُّ الأمر ولا الطالب. شكلُها اجتهادُ المدرسة — لا نموذجَ لها في النماذج السبعةَ عشر، والدليلُ الإجرائيُّ ص١٤٥ يقول للجلسات: «لا يوجد نموذج». 🔑 والبيئةُ الأسريّةُ والحالةُ الصحّيّة بابان مستقلّان لا حقلان هنا — كما في نور: «الملفّ الصحّيّ العائليّ» و«سجلّ زيارات أولياء الأمور». فإذا بُنيا قُرئا في هذي الدراسة ولم يُستجوب بهما الطالبُ ولا أسرتُه.';
