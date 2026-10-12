-- v2.card_due_steps
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d17c006455b2ca15976fa4d69d230dc2

CREATE TABLE v2.card_due_steps (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    owner_person uuid NOT NULL,
    kind text NOT NULL,
    code text,
    title_ar text NOT NULL,
    n_reached integer NOT NULL,
    threshold_n integer,
    opened_on date DEFAULT CURRENT_DATE NOT NULL,
    due_on date NOT NULL,
    answered_at timestamp with time zone,
    answered_by uuid,
    answer_note text,
    is_test boolean DEFAULT false NOT NULL,
    CONSTRAINT card_due_steps_pkey PRIMARY KEY (id),
    CONSTRAINT card_due_steps_kind_check CHECK ((kind = ANY (ARRAY['practice_threshold'::text, 'scatter'::text])))
);
CREATE INDEX ix_card_due_owner ON v2.card_due_steps USING btree (owner_person, due_on) WHERE (answered_at IS NULL);
CREATE UNIQUE INDEX ux_card_due_live ON v2.card_due_steps USING btree (student_id, kind, COALESCE(code, '—'::text), n_reached) WHERE (answered_at IS NULL);
ALTER TABLE v2.card_due_steps ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.card_due_steps IS 'خطواتُ بطاقة الطالب المستحقّةُ على المعلّم — لكلّ خطوةٍ صاحبٌ وموعدٌ وجواب. وعلّةُ بنائها أنّ القائمَ فتح ٧٠٠ حالةٍ واتُّخذ ١٢٣ إجراءً، لأنّ صاحبَ الخطوة الأولى (المعلّم) لم تكن له لوحةٌ تُريه ما يملكه.';
