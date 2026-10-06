-- v2.school_seats
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 c56ac63cb469184db261dd52916a4ce1

CREATE TABLE v2.school_seats (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    post_key text NOT NULL,
    person_id uuid,
    seat_no smallint DEFAULT 1 NOT NULL,
    is_acting boolean DEFAULT false NOT NULL,
    carries_post_key text,
    started_on date DEFAULT CURRENT_DATE NOT NULL,
    ended_on date,
    seat_source text DEFAULT 'entitled'::text NOT NULL,
    end_reason text,
    year_id uuid NOT NULL,
    CONSTRAINT school_seats_pkey PRIMARY KEY (id),
    CONSTRAINT school_seats_school_id_post_key_seat_no_started_on_key UNIQUE (school_id, post_key, seat_no, started_on),
    CONSTRAINT school_seats_end_reason_check CHECK ((end_reason = ANY (ARRAY['transferred'::text, 'resigned'::text, 'assignment_ended'::text, 'deceased'::text, 'leave'::text, 'year_closed'::text, 'other'::text]))),
    CONSTRAINT school_seats_end_reason_chk CHECK (((end_reason IS NULL) OR (ended_on IS NOT NULL))),
    CONSTRAINT school_seats_seat_source_check CHECK ((seat_source = ANY (ARRAY['entitled'::text, 'inherited'::text, 'assigned'::text])))
);
ALTER TABLE v2.school_seats ENABLE ROW LEVEL SECURITY;
