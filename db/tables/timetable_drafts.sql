-- v2.timetable_drafts
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 a63fa25cea8964d0bf2585a57442d64c

CREATE TABLE v2.timetable_drafts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    made_by uuid,
    made_at timestamp with time zone DEFAULT now() NOT NULL,
    state text DEFAULT 'مقترح'::text NOT NULL,
    applied_at timestamp with time zone,
    note_ar text,
    stats jsonb,
    applied_by uuid,
    CONSTRAINT timetable_drafts_pkey PRIMARY KEY (id),
    CONSTRAINT timetable_drafts_state_check CHECK ((state = ANY (ARRAY['مقترح'::text, 'مُقَرّ'::text, 'ملغًى'::text])))
);
ALTER TABLE v2.timetable_drafts ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.timetable_drafts IS 'مقترحُ جدولٍ يعرضه النظامُ ولا يثبّته — ولا يُطبَّق إلا بإقرار الإنسان';
