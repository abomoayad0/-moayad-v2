-- v2.guardian_replies
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 4b4f423520c53ccad305ab9523258e06

CREATE TABLE v2.guardian_replies (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    event_id uuid,
    task_id uuid,
    kind text NOT NULL,
    reply text NOT NULL,
    note_ar text,
    suggested date,
    replied_at timestamp with time zone DEFAULT now() NOT NULL,
    by_guardian uuid,
    CONSTRAINT guardian_replies_pkey PRIMARY KEY (id)
);
ALTER TABLE v2.guardian_replies ENABLE ROW LEVEL SECURITY;
