-- v2.absence_cases
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 8a3d8b7cdb53312a97a524fe08862efa

CREATE TABLE v2.absence_cases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint NOT NULL,
    student_id uuid NOT NULL,
    excused boolean NOT NULL,
    days_count smallint NOT NULL,
    ladder_id integer NOT NULL,
    triggered_on date DEFAULT CURRENT_DATE NOT NULL,
    consecutive boolean DEFAULT false NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    escalation_halted boolean DEFAULT false NOT NULL,
    halt_reason text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT absence_cases_pkey PRIMARY KEY (id),
    CONSTRAINT absence_cases_student_id_year_id_excused_ladder_id_key UNIQUE (student_id, year_id, excused, ladder_id),
    CONSTRAINT absence_cases_status_check CHECK ((status = ANY (ARRAY['open'::text, 'closed'::text])))
);
ALTER TABLE v2.absence_cases ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.absence_cases.escalation_halted IS 'الغياب لا يُمحى والعدّ تراكمي. فقبول العذر لا يحذف الحالة — يوقف تصعيدها ويردّ الدرجة المحسومة، وتبقى الحالة ومهامها المنفَّذة في السجل.';
