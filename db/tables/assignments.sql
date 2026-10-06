-- v2.assignments
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 db13e06bb66a32129596a28a711f93c0

CREATE TABLE v2.assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    post_key text NOT NULL,
    person_id uuid NOT NULL,
    seat_id uuid,
    letter_no text NOT NULL,
    letter_date date NOT NULL,
    issued_by uuid,
    issuer_post text DEFAULT 'principal'::text NOT NULL,
    reason text,
    is_entitled boolean DEFAULT false NOT NULL,
    started_on date NOT NULL,
    ended_on date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    end_reason text,
    year_id uuid NOT NULL,
    CONSTRAINT assignments_pkey PRIMARY KEY (id),
    CONSTRAINT assignments_check CHECK (((ended_on IS NULL) OR (ended_on >= started_on))),
    CONSTRAINT assignments_end_reason_check CHECK ((end_reason = ANY (ARRAY['transferred'::text, 'resigned'::text, 'assignment_ended'::text, 'deceased'::text, 'leave'::text, 'year_closed'::text, 'other'::text]))),
    CONSTRAINT assignments_end_reason_chk CHECK (((end_reason IS NULL) OR (ended_on IS NOT NULL))),
    CONSTRAINT assignments_letter_no_check CHECK ((length(btrim(letter_no)) > 0))
);
ALTER TABLE v2.assignments ENABLE ROW LEVEL SECURITY;
