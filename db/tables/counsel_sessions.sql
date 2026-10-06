-- v2.counsel_sessions
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 db4957d5a4f462ee117eb3538f794a86

CREATE TABLE v2.counsel_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    case_id uuid NOT NULL,
    session_no smallint NOT NULL,
    held_on date NOT NULL,
    minutes smallint,
    discussed text NOT NULL,
    response text NOT NULL,
    next_step text NOT NULL,
    by_person uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT counsel_sessions_pkey PRIMARY KEY (id),
    CONSTRAINT counsel_sessions_case_id_session_no_key UNIQUE (case_id, session_no),
    CONSTRAINT counsel_sessions_response_check CHECK ((response = ANY (ARRAY['تحسّنٌ ملحوظ'::text, 'تحسّنٌ طفيف'::text, 'السلوكُ مستمرّ'::text, 'تراجُع'::text])))
);
ALTER TABLE v2.counsel_sessions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.counsel_sessions IS 'جلساتُ متابعة الموجّه — 🔒 سرّيّةٌ؛ واللجنةُ ترى ملخَّصَها في التقرير لا نصَّها';
