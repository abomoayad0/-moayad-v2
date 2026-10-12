-- v2.card_sessions
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 8d1faa00b9c86e3d38351732d1c795b5

CREATE TABLE v2.card_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    person_id uuid NOT NULL,
    on_date date DEFAULT CURRENT_DATE NOT NULL,
    period_no smallint,
    slot_id uuid,
    blocked_why text,
    can_write boolean DEFAULT false NOT NULL,
    why_no_write text,
    opened_at timestamp with time zone DEFAULT now() NOT NULL,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT card_sessions_pkey PRIMARY KEY (id)
);
ALTER TABLE v2.card_sessions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.card_sessions IS 'جلسةُ بطاقة الطالب — وحدةٌ مستقلّة. تحفظ حالَ البطاقة لحظةَ فتحها: أمحجوبٌ الطالبُ، وأفي وقت الرصد فُتحت، ولماذا لا يُكتب إن لم يُكتب.';
