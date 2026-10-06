-- v2.committee_duties
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d2f19118b0ec1d4734a04e948b27534d

CREATE TABLE v2.committee_duties (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    committee_key text NOT NULL,
    school_id uuid,
    ord smallint DEFAULT 0 NOT NULL,
    text_ar text NOT NULL,
    cadence text,
    source_ar text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT committee_duties_pkey PRIMARY KEY (id),
    CONSTRAINT committee_duties_cadence_check CHECK ((cadence = ANY (ARRAY['مستمرّة'::text, 'شهريّة'::text, 'فصليّة'::text, 'سنويّة'::text, 'عند الحاجة'::text])))
);
ALTER TABLE v2.committee_duties ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.committee_duties IS 'مهامُّ اللجنة — ما نصّ عليه الدليلُ مشتركٌ (school_id فارغ)، وما زادته المدرسةُ خاصٌّ بها';
