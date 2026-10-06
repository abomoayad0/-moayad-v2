-- v2.timetable_draft_slots
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 57edc7de31b2aadfbada36c133b4c213

CREATE TABLE v2.timetable_draft_slots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    draft_id uuid NOT NULL,
    weekday smallint NOT NULL,
    period_no smallint NOT NULL,
    section_id uuid,
    person_id uuid,
    subject_ar text,
    slot_kind text DEFAULT 'teaching'::text NOT NULL,
    why_ar text,
    CONSTRAINT timetable_draft_slots_pkey PRIMARY KEY (id)
);
ALTER TABLE v2.timetable_draft_slots ENABLE ROW LEVEL SECURITY;
