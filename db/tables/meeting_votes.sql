-- v2.meeting_votes
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 0feaf978480b188cc5ed6c862db4ded5

CREATE TABLE v2.meeting_votes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    item_id uuid NOT NULL,
    person_id uuid NOT NULL,
    vote text NOT NULL,
    note_ar text,
    voted_at timestamp with time zone DEFAULT now() NOT NULL,
    prev_vote text,
    changed_at timestamp with time zone,
    change_note text,
    CONSTRAINT meeting_votes_pkey PRIMARY KEY (id),
    CONSTRAINT meeting_votes_item_id_person_id_key UNIQUE (item_id, person_id),
    CONSTRAINT meeting_votes_vote_check CHECK ((vote = ANY (ARRAY['موافق'::text, 'مخالف'::text, 'ممتنع'::text])))
);
ALTER TABLE v2.meeting_votes ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.meeting_votes IS 'اجتهادٌ موسوم: نمطُ القرار بالأغلبيّة ومن خالف يُثبت رأيَه — لا نصَّ في الدليل';
