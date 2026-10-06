-- v2.practice_overrides
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 7edc80647545be4b7e102391bbfaf3d1

CREATE TABLE v2.practice_overrides (
    school_id uuid NOT NULL,
    code text NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    title_ar text,
    points numeric,
    polarity text,
    scope text,
    kind text,
    zone text,
    once_per_day boolean,
    threshold_count smallint,
    threshold_days smallint,
    escalate_to integer,
    escalate_note text,
    note_ar text,
    ord smallint,
    set_by uuid,
    set_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT practice_overrides_pkey PRIMARY KEY (school_id, code),
    CONSTRAINT practice_overrides_polarity_check CHECK ((polarity = ANY (ARRAY['positive'::text, 'negative'::text])))
);
ALTER TABLE v2.practice_overrides ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.practice_overrides IS 'تعديلُ المدرسة على ممارسةٍ مشتركة — سطرٌ واحدٌ لا نسخة. فالكودُ يبقى واحدًا فلا ينقطع سجلُّ الطالب، وحذفُ السطر يُرجع الأصلَ تلقائيًّا.';
