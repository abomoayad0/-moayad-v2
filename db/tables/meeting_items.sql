-- v2.meeting_items
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 4f3600fe0a1ed48b25e2243a8d49626a

CREATE TABLE v2.meeting_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    meeting_id uuid NOT NULL,
    ord smallint DEFAULT 1 NOT NULL,
    subject_kind text DEFAULT 'طالب'::text NOT NULL,
    student_id uuid,
    record_id uuid,
    opp_ref uuid,
    title_ar text NOT NULL,
    body_ar text,
    decision_ar text,
    recommend_ar text,
    owner_person uuid,
    due_on date,
    outcome text DEFAULT 'قيد النظر'::text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT meeting_items_pkey PRIMARY KEY (id),
    CONSTRAINT meeting_items_outcome_check CHECK ((outcome = ANY (ARRAY['قيد النظر'::text, 'أُقرّ'::text, 'رُفض'::text, 'أُجّل'::text]))),
    CONSTRAINT meeting_items_subject_kind_check CHECK ((subject_kind = ANY (ARRAY['طالب'::text, 'عام'::text, 'فرصة'::text, 'تقرير'::text])))
);
CREATE INDEX ix_mi_meeting ON v2.meeting_items USING btree (meeting_id, ord);
ALTER TABLE v2.meeting_items ENABLE ROW LEVEL SECURITY;
