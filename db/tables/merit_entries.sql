-- v2.merit_entries
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 e12fc75806d94d1a80bf7f39be4401fd

CREATE TABLE v2.merit_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    opp_id uuid NOT NULL,
    student_id uuid NOT NULL,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    filed_at timestamp with time zone,
    what_ar text,
    evidence_name text,
    evidence_desc text,
    verdict text,
    verdict_note text,
    verdict_file text,
    verdict_by uuid,
    verdict_at timestamp with time zone,
    delegated_to uuid,
    delegate_note text,
    points numeric,
    graded_by uuid,
    graded_at timestamp with time zone,
    lifted_at timestamp with time zone,
    lifted_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    filed_by uuid,
    filed_as text,
    joined_by uuid,
    joined_as text,
    CONSTRAINT merit_entries_pkey PRIMARY KEY (id),
    CONSTRAINT merit_entries_opp_id_student_id_key UNIQUE (opp_id, student_id),
    CONSTRAINT merit_entries_verdict_check CHECK ((verdict = ANY (ARRAY['نفّذ'::text, 'نفّذ جزئيًّا'::text, 'لم ينفّذ'::text, 'لم يحضر'::text])))
);
ALTER TABLE v2.merit_entries ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.merit_entries IS 'مشاركةُ طالبٍ في فرصة — الطالبُ يملأ ويرفق · والمقرُّ يقرّ · والوكيلُ يرفع · واللجنةُ تقدّر';
