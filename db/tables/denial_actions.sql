-- v2.denial_actions
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 eab291625e964d87c387543438402e97

CREATE TABLE v2.denial_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    school_id uuid NOT NULL,
    student_id uuid NOT NULL,
    year_id uuid,
    kind text NOT NULL,
    days_absent integer,
    limit_days integer,
    committee_entry uuid,
    reason text,
    by_person uuid,
    on_date date DEFAULT CURRENT_DATE NOT NULL,
    event_id uuid,
    is_test boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT denial_actions_pkey PRIMARY KEY (id),
    CONSTRAINT denial_actions_kind_check CHECK ((kind = ANY (ARRAY['warning'::text, 'decision'::text, 'cancel'::text])))
);
CREATE INDEX denial_actions_school_idx ON v2.denial_actions USING btree (school_id, kind);
CREATE UNIQUE INDEX denial_one_warning_idx ON v2.denial_actions USING btree (student_id, year_id) WHERE (kind = 'warning'::text);
ALTER TABLE v2.denial_actions ENABLE ROW LEVEL SECURITY;
COMMENT ON TABLE v2.denial_actions IS 'الحرمانُ من الانتقال: إنذارٌ قبل الحدّ · ثمّ قرارُ المدير بعد عرضٍ على لجنة التوجيه · ولا يُحذف صفٌّ — والإلغاءُ صفٌّ ثالث';
