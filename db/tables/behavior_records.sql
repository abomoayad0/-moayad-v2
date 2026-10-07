-- v2.behavior_records
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 3bc7bfe71f7642250f542821fdac2f45

CREATE TABLE v2.behavior_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    term_no smallint,
    student_id uuid NOT NULL,
    problem_id integer NOT NULL,
    action_id integer NOT NULL,
    occurrence_no smallint NOT NULL,
    step_no smallint NOT NULL,
    occurred_on date DEFAULT CURRENT_DATE NOT NULL,
    period_no smallint,
    place text,
    recorded_by uuid,
    note text,
    victim_student_id uuid,
    has_injury boolean DEFAULT false NOT NULL,
    has_damage boolean DEFAULT false NOT NULL,
    has_seizure boolean DEFAULT false NOT NULL,
    seizure_is_legal_matter boolean DEFAULT false NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    voided_by uuid,
    void_reason text,
    closed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    incident_place_ar text,
    is_test boolean DEFAULT false NOT NULL,
    advice_ar text,
    CONSTRAINT behavior_records_pkey PRIMARY KEY (id),
    CONSTRAINT behavior_records_occurrence_no_check CHECK ((occurrence_no > 0)),
    CONSTRAINT behavior_records_status_check CHECK ((status = ANY (ARRAY['open'::text, 'closed'::text, 'voided'::text])))
);
CREATE INDEX br_student_idx ON v2.behavior_records USING btree (student_id, problem_id, year_id);
ALTER TABLE v2.behavior_records ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.behavior_records.incident_place_ar IS 'مكان ضبط الواقعة — محضر ضبط واقعة CONDUCT-1447-OFF ص68.';
