-- v2.committee_seats
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 729aa7ee6e4b9c3deb13d91f5434a6fc

CREATE TABLE v2.committee_seats (
    committee_key text NOT NULL,
    ord smallint NOT NULL,
    post_key text,
    seat_role text NOT NULL,
    seat_count smallint DEFAULT 1 NOT NULL,
    is_elected boolean DEFAULT false NOT NULL,
    elected_by text,
    qualification text,
    all_holders boolean DEFAULT false NOT NULL,
    CONSTRAINT committee_seats_pkey PRIMARY KEY (committee_key, ord),
    CONSTRAINT committee_seats_all_holders_chk CHECK (((NOT all_holders) OR ((post_key IS NOT NULL) AND (NOT is_elected)))),
    CONSTRAINT committee_seats_check CHECK (((NOT is_elected) OR (elected_by IS NOT NULL))),
    CONSTRAINT committee_seats_elected_by_check CHECK ((elected_by = ANY (ARRAY['admin_committee'::text, 'principal'::text]))),
    CONSTRAINT committee_seats_seat_count_check CHECK ((seat_count > 0)),
    CONSTRAINT committee_seats_seat_role_check CHECK ((seat_role = ANY (ARRAY['chair'::text, 'vice_chair'::text, 'rapporteur'::text, 'member'::text])))
);
ALTER TABLE v2.committee_seats ENABLE ROW LEVEL SECURITY;
