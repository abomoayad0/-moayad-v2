-- v2.committee_members
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 f76e052595774ffbbe155f03f2785e1c

CREATE TABLE v2.committee_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    committee_key text NOT NULL,
    person_id uuid NOT NULL,
    seat_role text NOT NULL,
    via_post_key text,
    is_elected boolean DEFAULT false NOT NULL,
    nominated_by text,
    started_on date DEFAULT CURRENT_DATE NOT NULL,
    ended_on date,
    end_reason text,
    year_id uuid NOT NULL,
    term_no smallint,
    CONSTRAINT committee_members_pkey PRIMARY KEY (id),
    CONSTRAINT committee_members_end_reason_check CHECK ((end_reason = ANY (ARRAY['transferred'::text, 'resigned'::text, 'assignment_ended'::text, 'deceased'::text, 'leave'::text, 'year_closed'::text, 'other'::text]))),
    CONSTRAINT committee_members_end_reason_chk CHECK (((end_reason IS NULL) OR (ended_on IS NOT NULL))),
    CONSTRAINT committee_members_seat_role_check CHECK ((seat_role = ANY (ARRAY['chair'::text, 'vice_chair'::text, 'rapporteur'::text, 'member'::text]))),
    CONSTRAINT committee_members_term_no_check CHECK (((term_no >= 1) AND (term_no <= 3)))
);
ALTER TABLE v2.committee_members ENABLE ROW LEVEL SECURITY;
