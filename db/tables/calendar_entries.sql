-- v2.calendar_entries
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 a28a4cc0e6f233be459563feb301e571

CREATE TABLE v2.calendar_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid NOT NULL,
    kind text NOT NULL,
    title text NOT NULL,
    starts_on date NOT NULL,
    ends_on date NOT NULL,
    is_school_day boolean DEFAULT false NOT NULL,
    source text,
    removed_at timestamp with time zone,
    removed_by uuid,
    removed_why text,
    CONSTRAINT calendar_entries_pkey PRIMARY KEY (id),
    CONSTRAINT calendar_entries_check CHECK ((ends_on >= starts_on)),
    CONSTRAINT calendar_entries_kind_check CHECK ((kind = ANY (ARRAY['holiday'::text, 'exam'::text, 'term_start'::text, 'term_end'::text, 'event'::text])))
);
ALTER TABLE v2.calendar_entries ENABLE ROW LEVEL SECURITY;
COMMENT ON COLUMN v2.calendar_entries.removed_at IS 'رُفع البندُ من العرض ولم يُحذف — فالأثرُ باقٍ ومعه سببُه.';
