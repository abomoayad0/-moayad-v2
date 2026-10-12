-- v2.period_covers
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 2ca741fcd548c19c77b4cc84004ea381

CREATE TABLE v2.period_covers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    year_id uuid,
    term_no smallint,
    on_date date NOT NULL,
    weekday smallint NOT NULL,
    period_no smallint NOT NULL,
    section_id uuid,
    subject_ar text,
    absent_person uuid,
    source_slot uuid,
    cover_person uuid,
    cover_basis text DEFAULT 'none'::text NOT NULL,
    decided text DEFAULT 'auto'::text NOT NULL,
    decided_by uuid,
    decided_at timestamp with time zone DEFAULT now() NOT NULL,
    why_ar text,
    gap_reason_ar text,
    invest_note_ar text,
    voided_at timestamp with time zone,
    voided_by uuid,
    void_why text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT period_covers_pkey PRIMARY KEY (id),
    CONSTRAINT period_covers_basis_ck CHECK ((cover_basis = ANY (ARRAY['standby'::text, 'free'::text, 'manual'::text, 'none'::text]))),
    CONSTRAINT period_covers_decided_ck CHECK ((decided = ANY (ARRAY['auto'::text, 'manual'::text, 'gap'::text]))),
    CONSTRAINT period_covers_gap_ck CHECK (((cover_person IS NOT NULL) OR (gap_reason_ar IS NOT NULL)))
);
CREATE UNIQUE INDEX period_covers_live_uq ON v2.period_covers USING btree (school_id, on_date, period_no, section_id) WHERE (voided_at IS NULL);
CREATE INDEX period_covers_person_ix ON v2.period_covers USING btree (school_id, cover_person, on_date);
ALTER TABLE v2.period_covers ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.period_covers IS 'تغطيةُ حصص الغائب من الاحتياط المعتمد في الجدول (س-٨-ا-١ ص٢٠١). ولا خانةَ موافقةٍ فيه — الموافقةُ وقعت عند عرض الجدول واعتماده.';
