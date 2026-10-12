-- v2.term_split_objections
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 6c864ea2611baf1edad9567d4a325a52

CREATE TABLE v2.term_split_objections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    grade smallint NOT NULL,
    subject_ar text NOT NULL,
    claim_unit smallint,
    evidence_ar text NOT NULL,
    raised_by uuid,
    raised_at timestamp with time zone DEFAULT now() NOT NULL,
    state text DEFAULT 'open'::text NOT NULL,
    answer_ar text,
    answered_by uuid,
    answered_at timestamp with time zone,
    CONSTRAINT term_split_objections_pkey PRIMARY KEY (id),
    CONSTRAINT term_split_objections_state_check CHECK ((state = ANY (ARRAY['open'::text, 'accepted'::text, 'declined'::text])))
);
ALTER TABLE v2.term_split_objections ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.term_split_objections IS 'اعتراضُ مدرسةٍ على حدّ الفصلين — لا تُعدّله بنفسها، فالحدُّ مرجعٌ مشتركٌ. تُبدي حجّتَها ويُصلح الحدُّ مرّةً للجميع.';
